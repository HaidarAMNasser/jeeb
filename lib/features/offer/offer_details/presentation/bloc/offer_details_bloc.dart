import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/offer/offer_details/data/repositories/offer_details_repository.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

part 'offer_details_event.dart';
part 'offer_details_state.dart';

class OfferDetailsBloc extends Bloc<OfferDetailsEvent, OfferDetailsState> {
  final OfferDetailsRepository _repository;

  OfferDetailsBloc(this._repository) : super(const OfferDetailsInitial()) {
    on<OfferDetailsEvent>((event, emit) async {
      if (event is GetOfferDetailsEvent) {
        emit(const OfferDetailsLoading());
        await Future.delayed(const Duration(milliseconds: 600));
        final offer = _fakeOfferDetails(event.id);
        emit(OfferDetailsLoaded(offer: offer));
      }
    });
  }

  OfferEntity _fakeOfferDetails(String id) {
    final idx = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return OfferEntity(
      id: id,
      shortDescription: 'Offer short description $id',
      longDescription:
          'Long description for this offer. Valid for limited time. Terms apply.',
      products: _fakeProducts(idx),
      startDate: DateTime.now().subtract(Duration(days: idx % 30)),
      endDate: DateTime.now().add(Duration(days: 7 + (idx % 14))),
      discountType: idx % 2 == 0 ? 'PERCENTAGE' : 'VALUE',
      discountValue: idx % 2 == 0 ? 15.0 : 500,
    );
  }

  List<ProductEntity> _fakeProducts(int seed) {
    return List.generate(3, (i) {
      final pid = seed * 10 + i;
      return ProductEntity(
        id: 'product_$pid',
        name: 'Product $pid',
        description: 'Description',
        shortDescription: 'Short',
        price: 1000 + pid * 100,
        priceAfterDiscount: 800,
        restaurantId: null,
        categoryId: '1',
        categoryName: 'Category',
        discount: 20,
        discountType: 'PERCENTAGE',
        hasStock: true,
        stockQuantity: 50,
        isAvailable: true,
        isExternal: false,
        merchantId: null,
        images: [
          ProductImageEntity(
            id: pid,
            url: 'https://picsum.photos/seed/$pid/400/400',
            mobileUrl: 'https://picsum.photos/seed/$pid/300/300',
            thumbnailUrl: 'https://picsum.photos/seed/$pid/150/150',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.0,
        createdAt: null,
        updatedAt: null,
      );
    });
  }
}
