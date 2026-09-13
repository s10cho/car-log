import 'package:flutter/material.dart';

/// The colour a vehicle is painted in.
///
/// A short list on purpose: these are the colours cars actually come in, and
/// a full picker would turn a two-second delight into a decision. The swatch
/// is the paint's base colour — the gloss and the highlight on it come from
/// the renderer, not from this value.
enum CarPaintColor {
  white('white', '화이트', Color(0xFFE8EAEC)),
  silver('silver', '실버', Color(0xFFB3B9C0)),
  gray('gray', '그레이', Color(0xFF6E747B)),
  black('black', '블랙', Color(0xFF1E2023)),
  red('red', '레드', Color(0xFFB3282D)),
  orange('orange', '오렌지', Color(0xFFD2691E)),
  yellow('yellow', '옐로', Color(0xFFDFAE1C)),
  green('green', '그린', Color(0xFF2F6B4A)),
  blue('blue', '블루', Color(0xFF1F5CA8)),
  navy('navy', '네이비', Color(0xFF27314F));

  const CarPaintColor(this.id, this.label, this.color);

  /// Stored in the database, so it must not change once shipped.
  final String id;

  final String label;

  final Color color;

  /// What a vehicle registered before colours existed is painted: nothing.
  /// A null colour leaves the model in the colour it was authored in, which
  /// is a real car colour too — not a missing value to paper over.
  static CarPaintColor? fromId(String? id) {
    for (final color in CarPaintColor.values) {
      if (color.id == id) {
        return color;
      }
    }
    return null;
  }
}
