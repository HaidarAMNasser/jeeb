class BasketSummaryModel {
  final int itemsSubtotal;
  final int offersSubtotal;
  final int totalSubtotal;
  final int totalDiscount;
  final int finalTotal;

  const BasketSummaryModel({
    required this.itemsSubtotal,
    required this.offersSubtotal,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.finalTotal,
  });

  factory BasketSummaryModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    return BasketSummaryModel(
      itemsSubtotal: asInt(json['itemsSubtotal']),
      offersSubtotal: asInt(json['offersSubtotal']),
      totalSubtotal: asInt(json['totalSubtotal']),
      totalDiscount: asInt(json['totalDiscount']),
      finalTotal: asInt(json['finalTotal']),
    );
  }
}
