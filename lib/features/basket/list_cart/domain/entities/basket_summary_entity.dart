import 'package:equatable/equatable.dart';

class BasketSummaryEntity extends Equatable {
  final int itemsSubtotal;
  final int offersSubtotal;
  final int totalSubtotal;
  final int totalDiscount;
  final int finalTotal;

  const BasketSummaryEntity({
    required this.itemsSubtotal,
    required this.offersSubtotal,
    required this.totalSubtotal,
    required this.totalDiscount,
    required this.finalTotal,
  });

  @override
  List<Object?> get props => [
        itemsSubtotal,
        offersSubtotal,
        totalSubtotal,
        totalDiscount,
        finalTotal,
      ];
}
