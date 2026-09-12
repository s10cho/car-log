#!/usr/bin/env python3
"""Embeds externally referenced textures into .glb files.

The Kenney Car Kit ships GLB models whose material points at
`Textures/colormap.png` by URI rather than embedding it, so a renderer that
only reads the .glb draws every car plain white. This rewrites each model with
the image inlined as a buffer view, leaving a single self-contained file per
car.

    python3 tool/embed_glb_textures.py <source-dir> <texture-dir> <out-dir>
"""
import json
import os
import struct
import sys


def read_glb(path):
    with open(path, 'rb') as handle:
        data = handle.read()
    magic, version, total = struct.unpack('<4sII', data[:12])
    if magic != b'glTF':
        raise ValueError(f'{path}: not a glb')
    offset, chunks = 12, {}
    while offset < total:
        length, kind = struct.unpack('<I4s', data[offset:offset + 8])
        chunks[kind.decode().strip('\x00')] = data[offset + 8:offset + 8 + length]
        offset += 8 + length + (-length % 4)
    return json.loads(chunks['JSON']), chunks.get('BIN', b'')


def write_glb(path, gltf, binary):
    def pad(chunk, filler):
        return chunk + filler * (-len(chunk) % 4)

    json_chunk = pad(json.dumps(gltf, separators=(',', ':')).encode(), b' ')
    bin_chunk = pad(binary, b'\x00')
    body = (
        struct.pack('<I4s', len(json_chunk), b'JSON') + json_chunk
        + struct.pack('<I4s', len(bin_chunk), b'BIN\x00') + bin_chunk
    )
    with open(path, 'wb') as handle:
        handle.write(struct.pack('<4sII', b'glTF', 2, 12 + len(body)) + body)


def embed(source, texture_dir, destination):
    gltf, binary = read_glb(source)
    changed = False

    for image in gltf.get('images', []):
        uri = image.get('uri')
        if uri is None:
            continue
        texture_path = os.path.join(texture_dir, os.path.basename(uri))
        if not os.path.exists(texture_path):
            raise FileNotFoundError(texture_path)

        with open(texture_path, 'rb') as handle:
            blob = handle.read()

        # Append to the binary chunk; glTF requires 4-byte aligned views.
        binary += b'\x00' * (-len(binary) % 4)
        view_offset = len(binary)
        binary += blob

        gltf.setdefault('bufferViews', []).append(
            {'buffer': 0, 'byteOffset': view_offset, 'byteLength': len(blob)}
        )
        image.pop('uri')
        image['bufferView'] = len(gltf['bufferViews']) - 1
        image['mimeType'] = 'image/png' if uri.lower().endswith('.png') else 'image/jpeg'
        changed = True

    if changed:
        binary += b'\x00' * (-len(binary) % 4)
        gltf.setdefault('buffers', [{}])[0]['byteLength'] = len(binary)
        gltf['buffers'][0].pop('uri', None)

    write_glb(destination, gltf, binary)
    return changed


def main():
    source_dir, texture_dir, out_dir = sys.argv[1:4]
    os.makedirs(out_dir, exist_ok=True)
    for name in sorted(os.listdir(source_dir)):
        if not name.endswith('.glb'):
            continue
        changed = embed(
            os.path.join(source_dir, name),
            texture_dir,
            os.path.join(out_dir, name),
        )
        size = os.path.getsize(os.path.join(out_dir, name))
        print(f'{name}: {"embedded" if changed else "unchanged"} ({size // 1024} KB)')


if __name__ == '__main__':
    main()
