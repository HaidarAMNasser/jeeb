import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/basket/manage_cart/data/repositories/manage_cart_repository.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_entity.dart';

part 'manage_cart_event.dart';
part 'manage_cart_state.dart';

class ManageCartBloc extends Bloc<ManageCartEvent, ManageCartState> {
  final ManageCartRepository _repository;

  ManageCartBloc(this._repository) : super(const ManageCartInitial()) {
    on<AddProductToCartEvent>(_onAdd);
    on<AddOfferToCartEvent>(_onAddOffer);
    on<UpdateCartItemQuantityEvent>(_onUpdate);
    on<RemoveCartItemEvent>(_onRemove);
    on<ClearCartEvent>(_onClear);
    on<ReplaceCartItemsEvent>(_onReplaceAll);
  }

  Future<void> _onAddOffer(
    AddOfferToCartEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    final result = await _repository.addOffer(
      offerId: event.offerId,
      quantity: event.quantity,
    );
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (basket) => emit(ManageCartSuccess(basket)),
    );
  }

  Future<void> _onAdd(
    AddProductToCartEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    final result = await _repository.addProduct(
      productId: event.productId,
      quantity: event.quantity,
    );
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (basket) => emit(ManageCartSuccess(basket)),
    );
  }

  Future<void> _onUpdate(
    UpdateCartItemQuantityEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    if (event.quantity < 1) {
      add(RemoveCartItemEvent(event.productId));
      return;
    }
    final result = await _repository.updateItemQuantity(
      productId: event.productId,
      quantity: event.quantity,
    );
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (basket) => emit(ManageCartSuccess(basket)),
    );
  }

  Future<void> _onRemove(
    RemoveCartItemEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    final result = await _repository.removeItem(event.productId);
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (basket) => emit(ManageCartSuccess(basket)),
    );
  }

  Future<void> _onClear(
    ClearCartEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    final result = await _repository.clearCart();
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (_) => emit(const ManageCartCleared()),
    );
  }

  Future<void> _onReplaceAll(
    ReplaceCartItemsEvent event,
    Emitter<ManageCartState> emit,
  ) async {
    emit(const ManageCartLoading());
    final result = await _repository.replaceCartItems(
      items: event.items,
      offers: event.offers,
    );
    result.fold(
      (failure) => emit(ManageCartError(failure.message)),
      (basket) => emit(ManageCartSuccess(basket)),
    );
  }
}
