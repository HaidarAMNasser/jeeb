import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
// import 'package:jeeb_app/features/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_details_content.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Load order details
    // context.read<OrderDetailsBloc>().add(
    //       GetOrderDetailsEvent(widget.orderId),
    //     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.orderDetails),
      body: Builder(
        builder: (context) {
          // return BlocStateHandler<OrderDetailsBloc, OrderDetailsState>(
          //   bloc: context.read<OrderDetailsBloc>(),
          //   isLoading: (state) => state is OrderDetailsLoading,
          //   isError: (state) => state is OrderDetailsError,
          //   getErrorMessage: (state) => (state as OrderDetailsError).message,
          //   getRetryCallback: (state) => () {
          //     context.read<OrderDetailsBloc>().add(
          //           GetOrderDetailsEvent(widget.orderId),
          //         );
          //   },
          //   successBuilder: (context, detailsState) {
          //     final loadedState = detailsState as OrderDetailsLoaded;
          //     return OrderDetailsContent(order: loadedState.order);
          //   },
          // );

          // Fake data for UI testing
          final fakeOrder = _generateFakeOrder();
          return OrderDetailsContent(order: fakeOrder);
        },
      ),
    );
  }

  // Fake data generation for UI testing
  OrderEntity _generateFakeOrder() {
    return OrderEntity(
      id: widget.orderId,
      products: _generateFakeProducts(),
      deliveryMan: _generateFakeDeliveryMan(),
      date: DateTime.now().subtract(const Duration(hours: 2)),
      longitude: 35.5018,
      latitude: 33.8938,
      numberOfPeople: 3,
      status: 'pending',
      merchantId: 'merchant_1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
  }

  List<ProductEntity> _generateFakeProducts() {
    return [
      ProductEntity(
        id: '1',
        name: 'Burger',
        description: 'Delicious burger with cheese',
        price: 1500,
        categoryId: 'cat1',
        categoryName: 'Fast Food',
        images: [
          ProductImageEntity(
            id: 1,
            url: 'https://picsum.photos/seed/product1/200/200',
            mobileUrl: 'https://picsum.photos/seed/product1/200/200',
            thumbnailUrl: 'https://picsum.photos/seed/product1/200/200',
            isMain: true,
            displayOrder: 1,
          ),
        ],
      ),
      ProductEntity(
        id: '2',
        name: 'Pizza',
        description: 'Margherita pizza',
        price: 2500,
        categoryId: 'cat1',
        categoryName: 'Fast Food',
        images: [
          ProductImageEntity(
            id: 2,
            url: 'https://picsum.photos/seed/product2/200/200',
            mobileUrl: 'https://picsum.photos/seed/product2/200/200',
            thumbnailUrl: 'https://picsum.photos/seed/product2/200/200',
            isMain: true,
            displayOrder: 1,
          ),
        ],
      ),
    ];
  }

  DeliveryManEntity _generateFakeDeliveryMan() {
    return DeliveryManEntity(
      id: '1',
      name: 'Ahmed Ali',
      phone: '+961 3 1234567',
      email: 'ahmed.ali@example.com',
      image: 'https://picsum.photos/seed/delivery1/200/200',
    );
  }
}
