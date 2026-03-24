import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

part 'delivery_home_event.dart';
part 'delivery_home_state.dart';

class DeliveryHomeBloc extends Bloc<DeliveryHomeEvent, DeliveryHomeState> {
  DeliveryHomeBloc() : super(const DeliveryHomeInitial()) {
    on<LoadDeliveryHomeEvent>(_onLoadHome);
    on<RefreshDeliveryHomeEvent>(_onRefreshHome);
  }

  Future<void> _onLoadHome(
    LoadDeliveryHomeEvent event,
    Emitter<DeliveryHomeState> emit,
  ) async {
    emit(const DeliveryHomeLoading());
    await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
    emit(DeliveryHomeLoaded(orders: _fakeOrders));
  }

  Future<void> _onRefreshHome(
    RefreshDeliveryHomeEvent event,
    Emitter<DeliveryHomeState> emit,
  ) async {
    // For refresh, we don't necessarily show a full loading screen
    await Future.delayed(const Duration(seconds: 1));
    emit(DeliveryHomeLoaded(orders: _fakeOrders));
  }

  // FAKE DATA
  final List<OrderEntity> _fakeOrders = [
    OrderEntity(
      id: 'ORD-001',
      status: 'PENDING',
      latitude: 30.0444,
      longitude: 31.2357,
      createdAt: DateTime.now(),
      products: const [
        ProductEntity(
          id: 'P1',
          name: 'Classic Burger',
          price: 1500, // $15.00
          merchantName: 'Burger King',
          images: [],
        ),
        ProductEntity(
          id: 'P2',
          name: 'Large Fries',
          price: 500, // $5.00
          merchantName: 'Burger King',
          images: [],
        ),
      ],
      deliveryMan: const DeliveryManEntity(
        id: 'DM1',
        name: 'Ahmed Mohamed',
        phone: '+20123456789',
        email: 'ahmed@example.com',
        cityName: 'Maadi, Cairo',
      ),
    ),
    OrderEntity(
      id: 'ORD-002',
      status: 'READY_FOR_PICKUP',
      latitude: 30.0595,
      longitude: 31.2234,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      products: const [
        ProductEntity(
          id: 'P3',
          name: 'Margherita Pizza',
          price: 2200, // $22.00
          merchantName: 'Pizza Hut',
          images: [],
        ),
      ],
      deliveryMan: const DeliveryManEntity(
        id: 'DM2',
        name: 'Sarah Khaled',
        phone: '+20198765432',
        email: 'sarah@example.com',
        cityName: 'Zamalek, Cairo',
      ),
    ),
    OrderEntity(
      id: 'ORD-003',
      status: 'ACCEPTED',
      latitude: 30.0700,
      longitude: 31.2500,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      products: const [
        ProductEntity(
          id: 'P4',
          name: 'Sushi Platter',
          price: 4500, // $45.00
          merchantName: 'Mori Sushi',
          images: [],
        ),
      ],
      deliveryMan: const DeliveryManEntity(
        id: 'DM3',
        name: 'John Doe',
        phone: '+20111222333',
        email: 'john@example.com',
        cityName: 'New Cairo',
      ),
    ),
  ];
}
