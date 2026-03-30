import 'package:jeeb_app/features/delivery/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';

extension OrderMapper on OrderModel {
  OrderEntity toDomain() {
    return OrderEntity(
      id: id,
      products: products != null && products!.isNotEmpty
          ? products!.map((p) => p.toDomain()).toList()
          : [],
      deliveryMan: deliveryMan?.toDomain(),
      date: date != null ? DateTime.tryParse(date!) : null,
      longitude: longitude,
      latitude: latitude,
      numberOfPeople: numberOfPeople,
      status: status,
      merchantId: merchantId,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      distance: distance,
      customerName: customerName,
      customerPhone: customerPhone,
      totalPrice: totalPrice,
      deliveryFee: deliveryFee,
      deliveryEarning: deliveryEarning,
      preparationTime: preparationTime,
      merchantPhone: merchantPhone,
      hideMerchantPhone: hideMerchantPhone,
    );
  }
}

extension OrderListMapper on List<OrderModel> {
  List<OrderEntity> toDomain() {
    return map((order) => order.toDomain()).toList();
  }
}

extension DeliveryManMapper on DeliveryManModel {
  DeliveryManEntity toDomain() {
    return DeliveryManEntity(
      id: id,
      name: name, // firstName + lastName
      phone: phone,
      email: email,
      cityName: cityName,
      countryName: countryName,
      image: imageUrl,
      isOnline: isOnline,
      officeOwnerId: officeOwnerId,
    );
  }
}

extension DeliveryManListMapper on List<DeliveryManModel> {
  List<DeliveryManEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}
