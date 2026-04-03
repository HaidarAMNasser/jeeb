import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/data/repositories/order_before_confirm_repository.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';

part 'order_before_confirm_event.dart';
part 'order_before_confirm_state.dart';

class OrderBeforeConfirmBloc
    extends Bloc<OrderBeforeConfirmEvent, OrderBeforeConfirmState> {
  OrderBeforeConfirmBloc(this._repository) : super(const OrderBeforeConfirmInitial()) {
    on<FetchOrderDataBeforeConfirm>(_onFetch);
    on<OrderBeforeConfirmReset>(_onReset);
  }

  final OrderBeforeConfirmRepository _repository;

  Future<void> _onFetch(
    FetchOrderDataBeforeConfirm event,
    Emitter<OrderBeforeConfirmState> emit,
  ) async {
    emit(const OrderBeforeConfirmLoading());
    final products = event.products
        .map(
          (e) => <String, dynamic>{
            'productId': e.productId,
            'quantity': e.quantity,
          },
        )
        .toList();

    final result = await _repository.calculateDeliveryCost(
      merchantId: event.merchantId,
      destinationLat: event.latitude,
      destinationLng: event.longitude,
      products: products,
    );

    result.fold(
      (f) => emit(OrderBeforeConfirmFailure(f.message)),
      (preview) => emit(OrderBeforeConfirmSuccess(preview)),
    );
  }

  void _onReset(
    OrderBeforeConfirmReset event,
    Emitter<OrderBeforeConfirmState> emit,
  ) {
    emit(const OrderBeforeConfirmInitial());
  }
}

/// Single cart line for the distance API `products` array.
class OrderBeforeConfirmProductRequest extends Equatable {
  const OrderBeforeConfirmProductRequest({
    required this.productId,
    required this.quantity,
  });

  final int productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}
