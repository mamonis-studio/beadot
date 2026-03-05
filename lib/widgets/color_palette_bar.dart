import 'package:flutter/material.dart';
import '../models/bead_color.dart';
import '../models/pattern_data.dart';

class ColorPaletteBar extends StatelessWidget {
  final PatternData pattern;
  final String? highlightColorId;
  final ValueChanged<String?> onColorTap;
  final String locale;

  const ColorPaletteBar({
    super.key,
    required this.pattern,
    this.highlightColorId,
    required this.onColorTap,
    this.locale = 'ja',
  });

  @override
  Widget build(BuildContext context) {
    final beadCounts = pattern.beadCounts;

    return Container(
      height: 64,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: beadCounts.length,
        itemBuilder: (context, index) {
          final entry = beadCounts[index];
          final color = entry.key;
          final count = entry.value;
          final isHighlighted = highlightColorId == color.id;

          return GestureDetector(
            onTap: () {
              if (isHighlighted) {
                onColorTap(null); // deselect
              } else {
                onColorTap(color.id);
              }
            },
            child: Container(
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHighlighted
                                ? const Color(0xFF111111)
                                : const Color(0xFFE0E0E0),
                            width: isHighlighted ? 2.5 : 1,
                          ),
                        ),
                        child: color.isSpecial
                            ? Center(
                                child: Text(
                                  '\u2726', // ✦
                                  style: TextStyle(
                                    color: color.contrastTextColor,
                                    fontSize: 10,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      // Count badge
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF888888),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    color.localizedName(locale),
                    style: const TextStyle(
                      fontSize: 7,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
