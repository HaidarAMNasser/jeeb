// This file represents a list of orders for the listing endpoint
// It uses the single OrderModel from order_details

// Type alias for clarity - the listing endpoint returns a list of orders
import 'package:jeeb_app/features/delivery/order/order_details/data/models/order_model.dart';

typedef ListOrderModel = List<OrderModel>;
