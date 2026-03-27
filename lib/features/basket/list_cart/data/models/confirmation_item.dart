class ConfirmationItem {
  final String productId;
  final bool isOffer;
  final String productName;
  final int quantity;
  final int unitPrice;

  const ConfirmationItem({
    required this.productId,
    this.isOffer = false,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  int get totalPrice => quantity * unitPrice;
}
