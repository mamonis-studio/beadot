import 'package:flutter/material.dart';
import '../models/plate_shape.dart';

class PlateShapeSelector extends StatelessWidget {
  final PlateShape selected;
  final ValueChanged<PlateShape> onChanged;
  final bool onlySquare; // true when non-Perler brand selected

  const PlateShapeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onlySquare = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PlateShape.values.map((shape) {
        final isSelected = shape == selected;
        final isDisabled = onlySquare && shape != PlateShape.square;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: isDisabled ? null : () => onChanged(shape),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF111111)
                    : isDisabled
                        ? const Color(0xFFF0F0F0)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? const Color(0xFFE0E0E0)
                      : const Color(0xFF111111),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                shape.iconChar,
                style: TextStyle(
                  fontSize: 20,
                  color: isSelected
                      ? Colors.white
                      : isDisabled
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF111111),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
