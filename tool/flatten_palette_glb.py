#!/usr/bin/env python3
"""Turns a palette-textured GLB into one with a flat material per colour.

Low-poly kits paint a whole vehicle by pointing every triangle at a swatch in
one small palette image. That is efficient and completely unrecolourable: the
body shares its material with the tyres, so there is no "the paint" to change.

This reads the palette, works out which swatch each triangle lands on, groups
the triangles by the colour they came out, and writes each group as its own
primitive with a plain colour material. The texture is dropped. What comes out
renders identically and *does* have a body material, which is what lets the
app paint a car the colour the user picked.

    python3 tool/flatten_palette_glb.py in.glb out.glb            # report
    python3 tool/flatten_palette_glb.py in.glb out.glb --body C3  # name one

Run with no --body first: it prints the groups with their colours and triangle
counts so the body can be picked by eye.
"""

from __future__ import annotations

import argparse
import io
import json
import struct
import sys
from collections import defaultdict

from PIL import Image

JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942

COMPONENT = {
    5120: ("b", 1),
    5121: ("B", 1),
    5122: ("h", 2),
    5123: ("H", 2),
    5125: ("I", 4),
    5126: ("f", 4),
}
COUNTS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path):
    data = open(path, "rb").read()
    magic, _, _ = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise SystemExit(f"{path} is not a GLB")
    gltf = None
    binary = b""
    offset = 12
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8 : offset + 8 + length]
        if kind == JSON_CHUNK:
            gltf = json.loads(chunk.decode("utf-8"))
        elif kind == BIN_CHUNK:
            binary = chunk
        offset += 8 + length
    return gltf, binary


def accessor_values(gltf, binary, index):
    """Every element of an accessor, as a list of tuples."""
    accessor = gltf["accessors"][index]
    fmt, size = COMPONENT[accessor["componentType"]]
    arity = COUNTS[accessor["type"]]
    view = gltf["bufferViews"][accessor["bufferView"]]
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    stride = view.get("byteStride") or size * arity

    out = []
    for i in range(accessor["count"]):
        at = start + i * stride
        out.append(struct.unpack_from("<" + fmt * arity, binary, at))
    return out


def sample(image, u, v):
    """Nearest-neighbour sample, the way a palette swatch is meant to be read.

    glTF puts UV (0, 0) at the image's top-left corner, which is also where
    Pillow puts pixel (0, 0) — so v maps straight to y with no flip. Flipping
    it lands on a different swatch entirely and paints the tyres cream.
    """
    width, height = image.size
    x = min(width - 1, max(0, int(u * width)))
    y = min(height - 1, max(0, int(v * height)))
    return image.getpixel((x, y))[:3]


def palette_image(gltf, binary, material_index):
    material = gltf["materials"][material_index]
    pbr = material.get("pbrMetallicRoughness") or {}
    texture = pbr.get("baseColorTexture")
    if texture is None:
        return None
    source = gltf["textures"][texture["index"]]["source"]
    image = gltf["images"][source]
    if "bufferView" not in image:
        raise SystemExit("texture is not embedded; nothing to sample")
    view = gltf["bufferViews"][image["bufferView"]]
    start = view.get("byteOffset", 0)
    raw = binary[start : start + view["byteLength"]]
    return Image.open(io.BytesIO(raw)).convert("RGB")


def _area(a, b, c):
    u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    cross = (
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    )
    return 0.5 * sum(x * x for x in cross) ** 0.5


def _distance(a, b):
    return sum(abs(x - y) for x, y in zip(a, b))


def srgb_to_linear(channel):
    c = channel / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("target")
    parser.add_argument(
        "--body",
        help="group id (as printed) to name Body, so the app can repaint it",
    )
    parser.add_argument(
        "--body-auto",
        action="store_true",
        help=(
            "pick the body automatically: the most saturated paint with a "
            "panel's worth of triangles. These kits shade the structure in "
            "greys and give the body the one real colour, so saturation finds "
            "it every time."
        ),
    )
    parser.add_argument(
        "--tolerance",
        type=int,
        default=75,
        help=(
            "how close two palette colours have to be (sum of channel "
            "differences) to count as the same paint. The swatches are "
            "gradients, not flat blocks, so without this a single panel "
            "becomes dozens of materials."
        ),
    )
    args = parser.parse_args()

    gltf, binary = read_glb(args.source)

    # First pass: what colour does each triangle come out, exactly.
    sampled = []  # (mesh, primitive, [(colour, (a, b, c)), ...])
    tally = defaultdict(int)
    area = defaultdict(float)
    for mesh_index, mesh in enumerate(gltf["meshes"]):
        for prim_index, primitive in enumerate(mesh["primitives"]):
            material_index = primitive.get("material")
            if material_index is None or "indices" not in primitive:
                continue
            image = palette_image(gltf, binary, material_index)
            if image is None:
                continue
            uvs = accessor_values(gltf, binary, primitive["attributes"]["TEXCOORD_0"])
            indices = [i[0] for i in accessor_values(gltf, binary, primitive["indices"])]

            positions = accessor_values(
                gltf, binary, primitive["attributes"]["POSITION"]
            )
            triangles = []
            for tri in range(0, len(indices), 3):
                a, b, c = indices[tri], indices[tri + 1], indices[tri + 2]
                u = (uvs[a][0] + uvs[b][0] + uvs[c][0]) / 3
                v = (uvs[a][1] + uvs[b][1] + uvs[c][1]) / 3
                colour = sample(image, u, v)
                tally[colour] += 1
                area[colour] += _area(positions[a], positions[b], positions[c])
                triangles.append((colour, (a, b, c)))
            sampled.append((mesh_index, prim_index, triangles))

    if not sampled:
        raise SystemExit("no palette-textured primitives found")

    # Second pass: collapse the gradient into paints. The most-used colour
    # seeds a group, everything within tolerance of a seed joins it, and what
    # is left seeds the next group. Seeding by frequency is what keeps the
    # representative colour the one the panel mostly is.
    colours = []
    for colour in sorted(tally, key=lambda c: -tally[c]):
        if all(_distance(colour, seed) > args.tolerance for seed in colours):
            colours.append(colour)
    groups = {}
    for colour in tally:
        groups[colour] = min(
            range(len(colours)), key=lambda i: _distance(colour, colours[i])
        )

    areas = defaultdict(float)
    for colour, value in area.items():
        areas[groups[colour]] += value

    per_primitive = []
    totals = defaultdict(int)
    for mesh_index, prim_index, triangles in sampled:
        buckets = defaultdict(list)
        for colour, corners in triangles:
            buckets[groups[colour]].extend(corners)
        for colour_id, indices in buckets.items():
            totals[colour_id] += len(indices) // 3
        per_primitive.append((mesh_index, prim_index, buckets))

    names = {}
    for colour_id, colour in enumerate(colours):
        hex_colour = "%02X%02X%02X" % colour
        names[colour_id] = f"C{colour_id}_{hex_colour}"
    body_id = None
    if args.body is not None:
        match = [i for i, n in names.items() if n.split("_")[0] == args.body]
        if not match:
            raise SystemExit(f"no group called {args.body}")
        body_id = match[0]
    elif args.body_auto:
        # Surface area, not triangle count. A van's cargo box is two enormous
        # triangles a side and would never clear a triangle threshold, while
        # the shaded structure underneath is thousands of small ones.
        total_area = sum(areas.values())
        candidates = [i for i in areas if areas[i] >= total_area * 0.05]
        if candidates:
            body_id = max(
                candidates, key=lambda i: max(colours[i]) - min(colours[i])
            )
    if body_id is not None:
        names[body_id] = "Body"

    print(f"{args.source}: {len(colours)} colours")
    for colour_id in sorted(totals, key=lambda i: -totals[i]):
        print(
            f"  {names[colour_id]:16s} rgb{colours[colour_id]}  "
            f"{totals[colour_id]} triangles"
        )

    # Rebuild: keep only the buffer views the surviving accessors point at,
    # then append one index buffer per (primitive, colour) group.
    kept_accessors = set()
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            kept_accessors.update(primitive["attributes"].values())
    for animation in gltf.get("animations", []):
        for sampler in animation.get("samplers", []):
            kept_accessors.update([sampler["input"], sampler["output"]])
    for skin in gltf.get("skins", []):
        if "inverseBindMatrices" in skin:
            kept_accessors.add(skin["inverseBindMatrices"])

    old_views = {}
    for accessor_index in kept_accessors:
        old_views[gltf["accessors"][accessor_index]["bufferView"]] = None

    out = bytearray()
    new_views = []
    for old_index in sorted(old_views):
        view = gltf["bufferViews"][old_index]
        start = view.get("byteOffset", 0)
        blob = binary[start : start + view["byteLength"]]
        while len(out) % 4:
            out += b"\x00"
        copied = {"buffer": 0, "byteOffset": len(out), "byteLength": len(blob)}
        out += blob
        if "byteStride" in view:
            copied["byteStride"] = view["byteStride"]
        if "target" in view:
            copied["target"] = view["target"]
        old_views[old_index] = len(new_views)
        new_views.append(copied)

    for accessor_index in kept_accessors:
        accessor = gltf["accessors"][accessor_index]
        accessor["bufferView"] = old_views[accessor["bufferView"]]

    new_accessors = gltf["accessors"]
    for mesh_index, prim_index, buckets in per_primitive:
        primitive = gltf["meshes"][mesh_index]["primitives"][prim_index]
        replacements = []
        for colour_id, indices in buckets.items():
            packed = struct.pack("<%dI" % len(indices), *indices)
            while len(out) % 4:
                out += b"\x00"
            offset = len(out)
            out += packed
            new_views.append(
                {
                    "buffer": 0,
                    "byteOffset": offset,
                    "byteLength": len(packed),
                    "target": 34963,
                }
            )
            new_accessors.append(
                {
                    "bufferView": len(new_views) - 1,
                    "componentType": 5125,
                    "count": len(indices),
                    "type": "SCALAR",
                }
            )
            replacements.append(
                {
                    "attributes": dict(primitive["attributes"]),
                    "indices": len(new_accessors) - 1,
                    "material": colour_id,
                    "mode": primitive.get("mode", 4),
                }
            )
        gltf["meshes"][mesh_index]["primitives"][prim_index] = replacements

    for mesh in gltf["meshes"]:
        flattened = []
        for primitive in mesh["primitives"]:
            if isinstance(primitive, list):
                flattened.extend(primitive)
            else:
                flattened.append(primitive)
        mesh["primitives"] = flattened

    gltf["materials"] = [
        {
            "name": names[colour_id],
            "pbrMetallicRoughness": {
                "baseColorFactor": [srgb_to_linear(c) for c in colour] + [1.0],
                "metallicFactor": 0.0,
                "roughnessFactor": 0.8,
            },
        }
        for colour_id, colour in enumerate(colours)
    ]
    gltf["bufferViews"] = new_views
    gltf["buffers"] = [{"byteLength": len(out)}]
    for key in ("images", "textures", "samplers"):
        gltf.pop(key, None)

    json_chunk = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(json_chunk) % 4:
        json_chunk += b" "
    while len(out) % 4:
        out += b"\x00"

    total = 12 + 8 + len(json_chunk) + 8 + len(out)
    with open(args.target, "wb") as handle:
        handle.write(struct.pack("<III", 0x46546C67, 2, total))
        handle.write(struct.pack("<II", len(json_chunk), JSON_CHUNK))
        handle.write(json_chunk)
        handle.write(struct.pack("<II", len(out), BIN_CHUNK))
        handle.write(bytes(out))
    print(f"  -> {args.target} ({total} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
