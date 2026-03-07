// This file represents a list of orders for the listing endpoint
// It uses the single OrderEntity from order_details
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

// Type alias for clarity - the listing endpoint returns a list of orders
typedef ListOrderEntity = List<OrderEntity>;
