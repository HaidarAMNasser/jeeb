import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

String fmtMinor(int minor) => '\$${(minor / 100).toStringAsFixed(2)}';

(int, int) subtotalAndFeeMinor(OrderEntity o) {
  final fee = (o.deliveryFee ?? 0).round();
  if (o.totalPrice != null) {
    final total = o.totalPrice!.round();
    return (total - fee, fee);
  }
  final items = o.itemsTotal?.round() ??
      o.products.fold<int>(0, (s, p) => s + p.displayPrice);
  final offers = o.offersTotal?.round() ?? 0;
  return (items + offers, fee);
}

String restaurantNameForOrder(OrderEntity order, String fallback) {
  final fromOwner = order.owner?.restaurantName?.trim();
  if (fromOwner != null && fromOwner.isNotEmpty) return fromOwner;
  if (order.products.isNotEmpty) {
    final m = order.products.first.merchantName;
    if (m != null && m.trim().isNotEmpty) return m.trim();
  }
  return fallback;
}

String restaurantAddressForOrder(OrderEntity order) {
  final fromOwner = order.owner?.address?.trim();
  if (fromOwner != null && fromOwner.isNotEmpty) return fromOwner;
  return '';
}

String customerNameForOrder(OrderEntity order, String fallback) {
  final n = order.displayCustomerName?.trim();
  if (n != null && n.isNotEmpty) return n;
  return fallback;
}

String customerAddressForOrder(OrderEntity order) {
  final a = order.displayCustomerAddressLine?.trim();
  if (a != null && a.isNotEmpty) return a;
  return '';
}

