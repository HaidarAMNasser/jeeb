import 'package:jeeb_app/features/delivery/order/create_order/areas/data/mappers/area_mapper.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';

extension OrderOwnerLocationMapper on OrderOwnerLocationModel {
  OrderOwnerLocationEntity toDomain() {
    return OrderOwnerLocationEntity(lat: lat, lng: lng);
  }
}

extension OrderCustomerMapper on OrderCustomerModel {
  OrderCustomerEntity toDomain() {
    return OrderCustomerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      address: address,
    );
  }
}

extension OrderRemainingTimeTextMapper on OrderRemainingTimeTextModel {
  OrderRemainingTimeTextEntity toDomain() {
    return OrderRemainingTimeTextEntity(
      text: text,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }
}

extension OrderRemainingTimeMapper on OrderRemainingTimeModel {
  OrderRemainingTimeEntity toDomain() {
    return OrderRemainingTimeEntity(text: text?.toDomain());
  }
}

extension OrderLineProductMapper on OrderLineProductModel {
  OrderLineProductEntity toDomain() {
    return OrderLineProductEntity(
      lineId: lineId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPriceMinor: unitPriceMinor,
      originalUnitPriceMinor: originalUnitPriceMinor,
      lineTotalMinor: lineTotalMinor,
      productDiscountValueMinor: productDiscountValueMinor,
    );
  }
}

extension OrderOfferBundleMapper on OrderOfferBundleModel {
  OrderOfferBundleEntity toDomain() {
    return OrderOfferBundleEntity(
      id: id,
      name: name,
      description: description?.isEmpty == true ? null : description,
      subtotalMinor: subtotalMinor,
      offerDiscountMinor: offerDiscountMinor,
      totalMinor: totalMinor,
      lines: lines.map((e) => e.toDomain()).toList(),
    );
  }
}

extension OrderOwnerMapper on OrderOwnerModel {
  OrderOwnerEntity toDomain() {
    return OrderOwnerEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      address: address,
      restaurantName: restaurantName,
      location: location?.toDomain(),
    );
  }
}

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
      itemsTotal: itemsTotal,
      offersTotal: offersTotal,
      deliveryFee: deliveryFee,
      deliveryEarning: deliveryEarning,
      preparationTime: preparationTime,
      mealPreparationMinutes: mealPreparationMinutes,
      deliveryTimeMinutes: deliveryTimeMinutes,
      merchantPhone: merchantPhone,
      hideMerchantPhone: hideMerchantPhone,
      owner: owner?.toDomain(),
      remainingTime: remainingTime?.toDomain(),
      customer: customer?.toDomain(),
      deliveryDeadline: deliveryDeadline != null
          ? DateTime.tryParse(deliveryDeadline!)
          : null,
      finalLocation: finalLocation?.toDomain(),
      itemLines: orderItemLines.map((e) => e.toDomain()).toList(),
      offerBundles: orderOfferBundles.map((e) => e.toDomain()).toList(),
      mediatorCommissionRate: mediatorCommissionRate,
      deliveryCostWithCommission: deliveryCostWithCommission,
      areaId: areaId,
      area: area?.toDomain(),
      subtotal: subtotal,
      productDiscount: productDiscount,
      offerDiscount: offerDiscount,
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
