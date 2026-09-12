import 'package:flutter/material.dart';

/// The shape of a vehicle, used to render it in 3D.
///
/// This is the one piece of a vehicle that exists purely for delight: the app
/// works identically whichever is chosen. It is a body *shape*, not a
/// manufacturer — shipping branded models would mean licensing someone's
/// trademark, and a generic shape the user recognises as "mine" does the job.
enum CarBodyStyle {
  sedan('sedan', '세단', Icons.directions_car),
  sedanSports('sedan-sports', '스포츠', Icons.sports_score),
  hatchback('hatchback-sports', '해치백', Icons.directions_car_filled),
  suv('suv', 'SUV', Icons.airport_shuttle),
  suvLuxury('suv-luxury', '대형 SUV', Icons.airport_shuttle),
  van('van', '밴', Icons.local_shipping),
  truck('truck', '트럭', Icons.fire_truck),
  delivery('delivery', '화물', Icons.local_shipping),
  taxi('taxi', '택시', Icons.local_taxi),
  police('police', '특장', Icons.local_police);

  const CarBodyStyle(this.id, this.label, this.icon);

  /// Stored in the database, so it must not change once shipped.
  final String id;

  final String label;

  /// Shown where 3D is unavailable or too heavy, such as list rows.
  final IconData icon;

  String get assetPath => 'assets/models/$id.glb';

  /// The style a vehicle falls back to — an unknown id from a newer build, or
  /// a vehicle created before styles existed.
  static const CarBodyStyle fallback = CarBodyStyle.sedan;

  static CarBodyStyle fromId(String? id) {
    for (final style in CarBodyStyle.values) {
      if (style.id == id) {
        return style;
      }
    }
    return fallback;
  }
}
