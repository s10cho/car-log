import 'package:flutter/material.dart';

/// The shape of a vehicle, used to render it in 3D.
///
/// This is the one piece of a vehicle that exists purely for delight: the app
/// works identically whichever is chosen. It is a body *type*, never a maker
/// or a model name.
enum CarBodyStyle {
  sedan('sedan', '세단', Icons.directions_car),
  sedanSports('sedan-sports', '스포츠', Icons.speed),
  hatchback('hatchback-sports', '해치백', Icons.directions_car_filled),
  suv('suv', 'SUV', Icons.airport_shuttle),
  suvLuxury('suv-luxury', '대형 SUV', Icons.airport_shuttle),
  van('van', '밴', Icons.local_shipping),
  truck('truck', '트럭', Icons.fire_truck),
  delivery('delivery', '화물', Icons.local_shipping);

  const CarBodyStyle(this.id, this.label, this.icon);

  /// Stored in the database, so it must not change once shipped.
  final String id;

  final String label;

  /// Shown where 3D is unavailable or too heavy, such as list rows.
  final IconData icon;

  /// The glTF material carrying the body colour.
  ///
  /// The kit paints every car from one shared palette image, which leaves no
  /// "the paint" to change. `tool/flatten_palette_glb.py` splits that into a
  /// material per colour and names the body's one `Body`, which is what makes
  /// the colour picker possible at all.
  Set<String> get paint => const {'Body'};

  String get assetPath => 'assets/models/$id.glb';

  /// The style a vehicle falls back to — an unknown id from a newer build, or
  /// a vehicle created before styles existed.
  static const CarBodyStyle fallback = CarBodyStyle.sedan;

  /// Styles that existed in an earlier build and no longer have a model, and
  /// the shape each becomes.
  ///
  /// Falling back to the default would turn a user's van into a car they never
  /// picked, so each retired id goes to the nearest shape that still exists.
  static const Map<String, CarBodyStyle> _retired = {
    // From the set of real-car shapes that briefly replaced this kit.
    'coupe': CarBodyStyle.sedanSports,
    'supercar': CarBodyStyle.sedanSports,
    'muscle': CarBodyStyle.sedanSports,
    'retro': CarBodyStyle.sedan,
    'luxury': CarBodyStyle.sedan,
    // A personal garage is not a taxi rank or a police motor pool.
    'taxi': CarBodyStyle.sedan,
    'police': CarBodyStyle.sedan,
  };

  static CarBodyStyle fromId(String? id) {
    for (final style in CarBodyStyle.values) {
      if (style.id == id) {
        return style;
      }
    }
    return _retired[id] ?? fallback;
  }
}
