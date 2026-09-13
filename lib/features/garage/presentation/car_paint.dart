import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../domain/car_body_style.dart';
import '../domain/car_paint_color.dart';

/// Materials in the models that are not paint, named the same way in each.
const String _glassMaterial = 'Windows';
const Set<String> _lightMaterials = {
  'Headlights',
  'TailLights',
  'WhiteLights',
  'BlueLights',
};

/// Repaints a freshly loaded car and gives every surface a finish.
///
/// The models ship as flat colours with no gloss at all, which is why they
/// read as plastic toys however good the lighting is. Paint wants a clearcoat
/// and a low roughness, glass wants to be a mirror, tyres want neither — and
/// once each surface says what it is made of, the environment lighting does
/// the rest.
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
      switch (material.name) {
        case final String name when name == style.paint:
          _paint(material, color?.color);
        case final String name when name == style.trim:
          // The second tone stays a second tone: a shade of the same paint,
          // not a colour of its own that would clash with every choice.
          _paint(material, color == null ? null : _darken(color.color));
        case _glassMaterial:
          material
            ..metallicFactor = 0.6
            ..roughnessFactor = 0.06;
        case final String name when _lightMaterials.contains(name):
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
        default:
          // Everything else is trim, tyre or grille: matte, never shiny.
          material
            ..metallicFactor = 0.0
            ..roughnessFactor = 0.7;
      }
    }
  }
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

Color _darken(Color color) => Color.lerp(color, const Color(0xFF000000), 0.35)!;

/// Swatches are authored in sRGB, the way a designer picks them; the renderer
/// shades in linear light. Handing it the sRGB numbers directly is the classic
/// washed-out-paint bug, so decode on the way in.
vm.Vector4 _linear(Color color) =>
    vm.Vector4(_decode(color.r), _decode(color.g), _decode(color.b), 1);

double _decode(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
