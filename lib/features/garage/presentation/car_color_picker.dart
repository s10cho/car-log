import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/car_paint_color.dart';

/// A row of paint swatches.
///
/// Swatches rather than a list of names: the choice is a colour, so the
/// control should be the colour itself. The name is still shown, once, for
/// the selected one — and it is what a screen reader reads out.
class CarColorPicker extends StatelessWidget {
  const CarColorPicker({
    required this.selected,
    required this.onSelected,
    this.size = 44,
    super.key,
  });

  final CarPaintColor? selected;
  final ValueChanged<CarPaintColor> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: size + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CarPaintColor.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = CarPaintColor.values[index];
          final isSelected = color == selected;
          return Semantics(
            button: true,
            selected: isSelected,
            label: color.label,
            child: GestureDetector(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                onSelected(color);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    // The ring is how a swatch says it is chosen; the outline
                    // on the others is what keeps a white car visible on a
                    // white background.
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
