part of 'list_cart_bloc.dart';

abstract class ListCartState extends Equatable {
  const ListCartState();

  @override
  List<Object?> get props => [];
}

class ListCartInitial extends ListCartState {
  const ListCartInitial();
}

class ListCartLoading extends ListCartState {
  const ListCartLoading();
}

class ListCartLoaded extends ListCartState {
  final List<CartDraftItem> originalItems;
  final List<CartDraftItem> currentItems;
  final String merchantName;
  final String customerPhone;
  final bool isSaving;
  final String? noticeMessage;
  final bool noticeIsError;

  const ListCartLoaded({
    required this.originalItems,
    required this.currentItems,
    required this.merchantName,
    this.customerPhone = '',
    this.isSaving = false,
    this.noticeMessage,
    this.noticeIsError = false,
  });

  bool get isEmpty => currentItems.isEmpty && originalItems.isEmpty;

  int get total => currentItems.fold(0, (sum, item) => sum + item.totalPrice);

  bool get isDirty {
    if (originalItems.length != currentItems.length) return true;
    for (final item in originalItems) {
      final current = currentItems.where(
        (e) => e.productId == item.productId && e.isOffer == item.isOffer,
      );
      if (current.isEmpty) return true;
      if (current.first.quantity != item.quantity) return true;
    }
    return false;
  }

  ListCartLoaded copyWith({
    List<CartDraftItem>? originalItems,
    List<CartDraftItem>? currentItems,
    String? merchantName,
    String? customerPhone,
    bool? isSaving,
    String? noticeMessage,
    bool clearNotice = false,
    bool? noticeIsError,
  }) {
    return ListCartLoaded(
      originalItems: originalItems ?? this.originalItems,
      currentItems: currentItems ?? this.currentItems,
      merchantName: merchantName ?? this.merchantName,
      customerPhone: customerPhone ?? this.customerPhone,
      isSaving: isSaving ?? this.isSaving,
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      noticeIsError: noticeIsError ?? this.noticeIsError,
    );
  }

  @override
  List<Object?> get props => [
        originalItems,
        currentItems,
        merchantName,
        customerPhone,
        isSaving,
        noticeMessage,
        noticeIsError,
      ];
}

class ListCartError extends ListCartState {
  final String message;

  const ListCartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartDraftItem extends Equatable {
  final String productId;
  final bool isOffer;
  final String productName;
  final String? imageUrl;
  final String? description;
  final int quantity;
  final int unitPrice;

  const CartDraftItem({
    required this.productId,
    this.isOffer = false,
    required this.productName,
    this.imageUrl,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  int get totalPrice => unitPrice * quantity;

  CartDraftItem copyWith({
    String? productId,
    bool? isOffer,
    String? productName,
    String? imageUrl,
    String? description,
    int? quantity,
    int? unitPrice,
  }) {
    return CartDraftItem(
      productId: productId ?? this.productId,
      isOffer: isOffer ?? this.isOffer,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        isOffer,
        productName,
        imageUrl,
        description,
        quantity,
        unitPrice,
      ];
}
