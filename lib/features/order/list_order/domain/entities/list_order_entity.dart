// This file represents a list of orders for the listing endpoint
// It uses the single OrderEntity from order_details

// Type alias for clarity - the listing endpoint returns a list of orders
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

typedef ListOrderEntity = List<OrderEntity>;

