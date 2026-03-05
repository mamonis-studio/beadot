import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/bead_color.dart';
import '../models/pattern_data.dart';
import '../services/database_service.dart';

enum ShoppingSortMode { byCount, byName }

class ShoppingListScreen extends StatefulWidget {
  final PatternData pattern;
  const ShoppingListScreen({super.key, required this.pattern});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<String, bool> _checks = {};
  ShoppingSortMode _sortMode = ShoppingSortMode.byCount;

  @override
  void initState() {
    super.initState();
    _loadChecks();
  }

  Future<void> _loadChecks() async {
    if (widget.pattern.dbId != null) {
      final checks = await DatabaseService.getShoppingChecks(widget.pattern.dbId!);
      setState(() => _checks = checks);
    }
  }

  Future<void> _toggleCheck(String colorId, bool value) async {
    setState(() => _checks[colorId] = value);
    if (widget.pattern.dbId != null) {
      await DatabaseService.setShoppingCheck(widget.pattern.dbId!, colorId, value);
    }
  }

  List<MapEntry<BeadColor, int>> get _sortedItems {
    final items = widget.pattern.beadCounts;
    switch (_sortMode) {
      case ShoppingSortMode.byCount:
        return items; // Already sorted by count desc
      case ShoppingSortMode.byName:
        return items..sort((a, b) => a.key.nameEn.compareTo(b.key.nameEn));
    }
  }

  void _copyAsText() {
    final l = AppLocalizations.of(context);
    final locale = l.locale;
    final buf = StringBuffer();
    buf.writeln('beadot - ${widget.pattern.settings.brand.displayNameEn}');
    buf.writeln('${widget.pattern.totalBeads}${l.pieces} / ${widget.pattern.usedColorCount}${l.colors}');
    buf.writeln('---');
    for (final entry in _sortedItems) {
      final name = entry.key.localizedName(locale);
      buf.writeln('${entry.key.id} $name: ${entry.value}${l.pieces}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.copyText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = l.locale;
    final items = _sortedItems;
    final checkedCount = _checks.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.shoppingList),
        actions: [
          IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: _copyAsText),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: const Color(0xFFF8F8F8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l.total}: ${widget.pattern.totalBeads}${l.pieces} / ${widget.pattern.usedColorCount}${l.colors}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$checkedCount/${items.length}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),

          // Sort toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _sortMode = ShoppingSortMode.byCount),
                  child: Text(
                    l.sortByCount,
                    style: TextStyle(
                      fontSize: 12,
                      color: _sortMode == ShoppingSortMode.byCount
                          ? const Color(0xFF111111) : const Color(0xFFBBBBBB),
                      fontWeight: _sortMode == ShoppingSortMode.byCount
                          ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                const Text(' / ', style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB))),
                GestureDetector(
                  onTap: () => setState(() => _sortMode = ShoppingSortMode.byName),
                  child: Text(
                    l.sortByName,
                    style: TextStyle(
                      fontSize: 12,
                      color: _sortMode == ShoppingSortMode.byName
                          ? const Color(0xFF111111) : const Color(0xFFBBBBBB),
                      fontWeight: _sortMode == ShoppingSortMode.byName
                          ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final entry = items[index];
                final color = entry.key;
                final count = entry.value;
                final isChecked = _checks[color.id] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  child: Row(
                    children: [
                      // Checkbox
                      GestureDetector(
                        onTap: () => _toggleCheck(color.id, !isChecked),
                        child: Container(
                          width: 24, height: 24,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFF111111) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isChecked ? const Color(0xFF111111) : const Color(0xFFCCCCCC),
                              width: 1.5,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),

                      // Color circle
                      Container(
                        width: 28, height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                      ),

                      // Name + ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              color.localizedName(locale),
                              style: TextStyle(
                                fontSize: 14,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked ? const Color(0xFFBBBBBB) : const Color(0xFF111111),
                              ),
                            ),
                            Text(
                              color.id,
                              style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
                            ),
                          ],
                        ),
                      ),

                      // Count
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isChecked ? const Color(0xFFBBBBBB) : const Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
