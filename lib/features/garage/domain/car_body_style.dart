import 'package:flutter/material.dart';

/// The shape of a vehicle, used to render it in 3D.
///
/// This is the one piece of a vehicle that exists purely for delight: the app
/// works identically whichever is chosen. It is a body *shape*, not a
/// manufacturer — shipping branded models would mean licensing someone's
/// trademark, and a generic shape the user recognises as "mine" does the job.
enum CarBodyStyle {
  sedan('sedan', '세단', Icons.directions_car, paint: 'Blue'),
  sedanSports('sedan-sports', '스포츠 세단', Icons.sports_score, paint: 'White'),
  coupe(
    'coupe',
    '쿠페',
    Icons.time_to_leave,
    paint: 'Orange',
    trim: 'DarkOrange',
  ),
  hatchback(
    'hatchback-sports',
    '해치백',
    Icons.directions_car_filled,
    paint: 'LightBlue',
  ),
  retro('retro', '클래식', Icons.auto_awesome, paint: 'Main'),
  suv('suv', 'SUV', Icons.airport_shuttle, paint: 'White'),
  taxi('taxi', '택시', Icons.local_taxi, paint: 'Yellow'),
  police('police', '경찰차', Icons.local_police, paint: 'White');

  const CarBodyStyle(
    this.id,
    this.label,
    this.icon, {
    required this.paint,
    this.trim,
  });

  /// Stored in the database, so it must not change once shipped.
  final String id;

  final String label;

  /// Shown where 3D is unavailable or too heavy, such as list rows.
  final IconData icon;

  /// The glTF material that carries the body colour in this model.
  ///
  /// Each model names it after the colour it was authored in ("Blue",
  /// "Yellow"), so there is no naming convention to rely on — the name is
  /// recorded here per model and looked up when the car is painted.
  final String paint;

  /// A second painted panel, where the model has one (a lower body, a skirt).
  /// Painted a shade darker than [paint] so the two-tone survives recolouring.
  final String? trim;

  String get assetPath => 'assets/models/$id.glb';

  /// The style a vehicle falls back to — an unknown id from a newer build, or
  /// a vehicle created before styles existed.
  static const CarBodyStyle fallback = CarBodyStyle.sedan;

  /// Styles that existed in an earlier build and no longer have a model, and
  /// the shape each becomes.
  ///
  /// The old low-poly kit had a van, a truck and a large SUV. Those bodies do
  /// not exist in the kit that replaced it, and silently falling back to a
  /// sedan would turn a user's van into a car they never picked. The nearest
  /// remaining shape is a better answer than the default one.
  static const Map<String, CarBodyStyle> _retired = {
    'suv-luxury': CarBodyStyle.suv,
    'van': CarBodyStyle.suv,
    'truck': CarBodyStyle.suv,
    'delivery': CarBodyStyle.suv,
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
