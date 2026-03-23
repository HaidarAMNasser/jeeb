class ConfirmationItem {
  final String productName;
  final int quantity;
  final int unitPrice;

  const ConfirmationItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  int get totalPrice => quantity * unitPrice;
}
