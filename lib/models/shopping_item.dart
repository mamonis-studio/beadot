import 'bead_color.dart';

class ShoppingItem {
  final BeadColor beadColor;
  final int quantity;
  bool isChecked;

  ShoppingItem({
    required this.beadColor,
    required this.quantity,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
        'color_id': beadColor.id,
        'quantity': quantity,
        'is_checked': isChecked,
      };
}
