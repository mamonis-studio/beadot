import 'package:flutter/material.dart';

class SegmentControl<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final double height;

  const SegmentControl({
    super.key,
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF111111), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = item == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF111111) : Colors.transparent,
                    border: index > 0
                        ? const Border(left: BorderSide(color: Color(0xFF111111), width: 1.5))
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labelBuilder(item),
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF111111),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
