import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';
import 'package:jeeb_app/features/delivery/order/create_order/domain/entities/create_order_params.dart';

abstract class CreateOrderRemoteDataSource {
  Future<Response> createOrder(CreateOrderParams params);
}

class CreateOrderRemoteDataSourceImpl implements CreateOrderRemoteDataSource {
  final AppApiServiceClient _client;

  CreateOrderRemoteDataSourceImpl(this._client);

  @override
  Future<Response> createOrder(CreateOrderParams params) {
    final body = _requestBodyFromParams(params);
    return _client.createOrder(body);
  }

  Map<String, dynamic> _requestBodyFromParams(CreateOrderParams params) {
    final delivery = <String, dynamic>{
      'latitude': params.delivery.latitude,
      'longitude': params.delivery.longitude,
    };
    final addr = params.delivery.address;
    if (addr != null && addr.isNotEmpty) {
      delivery['address'] = addr;
    }
    final lm = params.delivery.landmark;
    if (lm != null && lm.isNotEmpty) {
      delivery['landmark'] = lm;
    }
    final notes = params.delivery.specialInstructions;
    if (notes != null && notes.isNotEmpty) {
      delivery['specialInstructions'] = notes;
    }

    final body = <String, dynamic>{
      'ownerId': params.ownerId,
      'deliveryCoordinates': delivery,
      'deliveryFee': params.deliveryFee,
      'paymentMethod': params.paymentMethod,
      'tipAmount': params.tipAmount,
    };

    final cid = params.cityId;
    if (cid != null && cid > 0) {
      body['cityId'] = cid;
    }
    final name = params.customerName;
    if (name != null && name.isNotEmpty) {
      body['customerName'] = name;
    }
    final phone = params.customerPhone;
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    if (params.products.isNotEmpty) {
      body['items'] = params.products
          .map((e) => {'productId': e.productId, 'quantity': e.quantity})
          .toList();
    }
    if (params.offers.isNotEmpty) {
      body['offers'] = params.offers
          .map((e) => {'offerId': e.offerId, 'quantity': e.quantity})
          .toList();
    }

    return body;
  }
}
