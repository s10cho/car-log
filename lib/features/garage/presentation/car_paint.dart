import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../domain/car_body_style.dart';
import '../domain/car_paint_color.dart';

/// Repaints a freshly loaded car and gives every surface a finish.
///
/// The models ship as flat colours with no gloss at all, which is why they
/// read as plastic toys however good the lighting is. Paint wants a clearcoat
/// and a low roughness, glass wants to be a mirror, tyres want neither — and
/// once each surface says what it is made of, the environment lighting does
/// the rest.
///
/// Material names come from whoever authored each model, so everything except
/// the body is matched on what the name *contains* rather than on an exact
/// spelling: one car calls its glass `Windows`, another `glass`, a third
/// `Window glass`. The body is the exception — it is named per model in
/// [CarBodyStyle.paint], because "which material is the paint" is a judgement
/// no substring can make.
///
/// [color] of null leaves the body in the colour the model was authored in,
/// for vehicles registered before there was a colour to pick.
void paintCar(Node car, CarBodyStyle style, CarPaintColor? color) {
  for (final node in car.meshNodes) {
    for (final primitive in node.mesh!.primitives) {
      final material = primitive.material;
      if (material is! PhysicallyBasedMaterial) {
        continue;
      }
      final name = material.name;
      if (style.paint.contains(name)) {
        _paint(material, color?.color);
      } else if (_matches(name, const ['glass', 'window', 'windshield'])) {
        // Authored glass ranges from clear to milky white, and a light tint
        // shading a bright studio sky comes out as a solid white panel. Dark
        // and shiny is what reads as a car window from the outside.
        material
          ..baseColorFactor = vm.Vector4(0.02, 0.025, 0.03, 1)
          ..metallicFactor = 0.3
          ..roughnessFactor = 0.08;
      } else if (_matches(name, const ['light', 'lamp'])) {
        // Lamps read as lit glass rather than painted-on colour.
        material
          ..emissiveFactor = vm.Vector4(
            material.baseColorFactor.r,
            material.baseColorFactor.g,
            material.baseColorFactor.b,
            1,
          )
          ..emissiveStrength = 0.6
          ..roughnessFactor = 0.2;
      } else if (_matches(name, const ['rim', 'chrome', 'metal', 'kidney'])) {
        // Wheel rims and brightwork: the one place a mirror finish belongs.
        material
          ..metallicFactor = 0.9
          ..roughnessFactor = 0.25;
      } else {
        // Everything else is trim, tyre or grille: matte, never shiny.
        //
        // Alpha is forced closed. Some models carry a half-transparent
        // material on a roof or a pillar, left over from how they were
        // authored, and a car you can see straight through is not a car —
        // one of them arrived looking like it had lost its roof.
        final base = material.baseColorFactor;
        material
          ..baseColorFactor = vm.Vector4(base.r, base.g, base.b, 1)
          ..alphaMode = AlphaMode.opaque
          ..metallicFactor = 0.0
          ..roughnessFactor = 0.7;
      }
    }
  }
}

bool _matches(String name, List<String> needles) {
  final lower = name.toLowerCase();
  return needles.any(lower.contains);
}

void _paint(PhysicallyBasedMaterial material, Color? color) {
  if (color != null) {
    material.baseColorFactor = _linear(color);
  }
  material
    // A little metallic for the flake, a clearcoat for the lacquer over it.
    //
    // Both are kept low. Turned up, the studio sky reflects almost whole off
    // every up-facing panel, and a navy car ends up with a light grey roof
    // and bonnet — the paint stops being the colour the user chose.
    ..metallicFactor = 0.1
    ..roughnessFactor = 0.42
    ..clearcoat = 0.55
    ..clearcoatRoughness = 0.2;
}

/// Swatches are authored in sRGB, the way a designer picks them; the renderer
/// shades in linear light. Handing it the sRGB numbers directly is the classic
/// washed-out-paint bug, so decode on the way in.
vm.Vector4 _linear(Color color) =>
    vm.Vector4(_decode(color.r), _decode(color.g), _decode(color.b), 1);

double _decode(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
