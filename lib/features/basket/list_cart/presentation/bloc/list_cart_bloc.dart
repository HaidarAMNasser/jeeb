import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/data/repositories/list_cart_repository.dart';
import 'package:jeeb_app/features/basket/manage_cart/data/repositories/manage_cart_repository.dart';

part 'list_cart_event.dart';
part 'list_cart_state.dart';

class ListCartBloc extends Bloc<ListCartEvent, ListCartState> {
  final ListCartRepository _repository;
  final ManageCartRepository _manageRepository;

  ListCartBloc(this._repository, this._manageRepository)
      : super(const ListCartInitial()) {
    on<LoadCartEvent>(_onLoad);
    on<IncreaseCartItemEvent>(_onIncrease);
    on<DecreaseCartItemEvent>(_onDecrease);
    on<SaveCartChangesEvent>(_onSave);
    on<ClearCartNoticeEvent>(_onClearNotice);
    on<ClearEntireCartEvent>(_onClearEntireCart);
  }

  Future<void> _onLoad(LoadCartEvent event, Emitter<ListCartState> emit) async {
    emit(const ListCartLoading());
    final result = await _repository.getCart();
    result.fold(
      (failure) => emit(ListCartError(failure.message)),
      (basket) {
        if (basket == null || basket.items.isEmpty) {
          emit(
            const ListCartLoaded(
              originalItems: [],
              currentItems: [],
              merchantName: '',
            ),
          );
          return;
        }
        final draftItems = basket.items
            .map(
              (e) => CartDraftItem(
                productId: e.product.id,
                productName: e.product.name,
                imageUrl: e.product.images.isNotEmpty ? e.product.images.first.url : null,
                description: e.product.shortDescription ?? e.product.description,
                quantity: e.quantity,
                unitPrice: e.unitPrice,
              ),
            )
            .toList();
        emit(
          ListCartLoaded(
            originalItems: draftItems,
            currentItems: draftItems,
            merchantName: basket.merchantName ?? '',
          ),
        );
      },
    );
  }

  void _onIncrease(IncreaseCartItemEvent event, Emitter<ListCartState> emit) {
    final current = state;
    if (current is! ListCartLoaded) return;
    final updated = current.currentItems
        .map(
          (e) => e.productId == event.productId
              ? e.copyWith(quantity: e.quantity + 1)
              : e,
        )
        .toList();
    emit(current.copyWith(currentItems: updated));
  }

  void _onDecrease(DecreaseCartItemEvent event, Emitter<ListCartState> emit) {
    final current = state;
    if (current is! ListCartLoaded) return;
    final updated = <CartDraftItem>[];
    for (final item in current.currentItems) {
      if (item.productId != event.productId) {
        updated.add(item);
        continue;
      }
      if (item.quantity > 1) {
        updated.add(item.copyWith(quantity: item.quantity - 1));
      }
    }
    emit(current.copyWith(currentItems: updated));
  }

  Future<void> _onSave(
    SaveCartChangesEvent event,
    Emitter<ListCartState> emit,
  ) async {
    final current = state;
    if (current is! ListCartLoaded || !current.isDirty) return;
    emit(current.copyWith(isSaving: true, clearNotice: true));

    final payload = current.currentItems
        .map(
          (e) => {
            'productId': int.tryParse(e.productId),
            'quantity': e.quantity,
          },
        )
        .where((e) => e['productId'] != null)
        .map(
          (e) => {
            'productId': e['productId'] as int,
            'quantity': e['quantity'] as int,
          },
        )
        .toList();

    final result = await _manageRepository.replaceCartItems(payload);
    result.fold(
      (failure) => emit(
        current.copyWith(
          isSaving: false,
          noticeMessage: failure.message,
          noticeIsError: true,
        ),
      ),
      (_) => add(const LoadCartEvent()),
    );
  }

  void _onClearNotice(ClearCartNoticeEvent event, Emitter<ListCartState> emit) {
    final current = state;
    if (current is! ListCartLoaded) return;
    emit(current.copyWith(clearNotice: true));
  }

  Future<void> _onClearEntireCart(
    ClearEntireCartEvent event,
    Emitter<ListCartState> emit,
  ) async {
    final current = state;
    if (current is! ListCartLoaded) return;
    emit(current.copyWith(isSaving: true, clearNotice: true));

    final result = await _manageRepository.clearCart();
    result.fold(
      (failure) => emit(
        current.copyWith(
          isSaving: false,
          noticeMessage: failure.message,
          noticeIsError: true,
        ),
      ),
      (_) => emit(
        const ListCartLoaded(
          originalItems: [],
          currentItems: [],
          merchantName: '',
          noticeMessage: 'Cart cleared successfully',
          noticeIsError: false,
        ),
      ),
    );
  }
}
