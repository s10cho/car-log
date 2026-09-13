import 'package:flutter/material.dart';

/// The shape of a vehicle, used to render it in 3D.
///
/// This is the one piece of a vehicle that exists purely for delight: the app
/// works identically whichever is chosen. The names here are generic — a body
/// *type*, never a maker or a model name — because a trademark has no business
/// in a garage app's UI.
enum CarBodyStyle {
  sedan('sedan', '세단', Icons.directions_car, paint: {'Red_Chasis'}),
  sedanSports(
    'sedan-sports',
    '스포츠 세단',
    Icons.speed,
    paint: {'chasis', 'chasis_NONE'},
  ),
  coupe('coupe', 'JDM 쿠페', Icons.time_to_leave, paint: {'Body', 'Body.001'}),
  supercar('supercar', '슈퍼카', Icons.local_fire_department, paint: {'bodywork'}),
  muscle('muscle', '머슬', Icons.bolt, paint: {'bodywork'}),
  retro('retro', '클래식', Icons.auto_awesome, paint: {'Chasis'}),
  luxury('luxury', '럭셔리', Icons.workspace_premium, paint: {'car'}),
  suv('suv', 'SUV', Icons.airport_shuttle, paint: {'White'}),
  van('van', '밴', Icons.local_shipping, paint: {'bodywork'});

  const CarBodyStyle(this.id, this.label, this.icon, {required this.paint});

  /// Stored in the database, so it must not change once shipped.
  final String id;

  final String label;

  /// Shown where 3D is unavailable or too heavy, such as list rows.
  final IconData icon;

  /// The glTF materials that carry the body colour in this model.
  ///
  /// Every model was authored by a different hand, so the body material is
  /// called whatever that author called it — `bodywork`, `chasis`, `Body`.
  /// There is no convention to lean on; the names are recorded here per model
  /// and looked up when the car is painted. Some models split the body across
  /// two materials, hence a set.
  final Set<String> paint;

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
    'suv-luxury': CarBodyStyle.suv,
    'truck': CarBodyStyle.van,
    'delivery': CarBodyStyle.van,
    'hatchback-sports': CarBodyStyle.coupe,
    // A personal garage is not a taxi rank or a police motor pool. Both are
    // gone; a vehicle that had one becomes an ordinary saloon.
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
