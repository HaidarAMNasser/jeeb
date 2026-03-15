import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

  import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/data/repositories/list_offer_repository.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
part 'list_offer_event.dart';
part 'list_offer_state.dart';

class ListOfferBloc extends Bloc<ListOfferEvent, ListOfferState> {
  final ListOfferRepository _repository;
  static const int _pageSize = 20;

  ListOfferBloc(this._repository) : super(const ListOfferInitial()) {
    on<ListOfferEvent>((event, emit) async {
      if (event is GetOffersEvent) {
        if (event.loadMore) {
          final currentState = state;
          if (currentState is ListOfferLoaded) {
            emit(ListOfferLoadingMore(
              offers: currentState.offers,
              currentPage: currentState.currentPage,
            ));
            await Future.delayed(const Duration(milliseconds: 500));
            final nextPage = currentState.currentPage + 1;
            final moreOffers = _generateFakeOffers(
              startIndex: currentState.offers.length,
              count: 10,
              merchantId: currentState.merchantId,
            );
            emit(ListOfferLoaded(
              offers: [...currentState.offers, ...moreOffers],
              hasMore: moreOffers.length == _pageSize,
              currentPage: nextPage,
              merchantId: currentState.merchantId,
            ));
          }
        } else {
          emit(const ListOfferLoading());
          await Future.delayed(const Duration(milliseconds: 800));
          final offers = _generateFakeOffers(
            startIndex: 0,
            count: _pageSize,
            merchantId: event.merchantId,
          );
          emit(ListOfferLoaded(
            offers: offers,
            hasMore: offers.length == _pageSize,
            currentPage: 1,
            merchantId: event.merchantId,
          ));
        }
      }
    });
  }

  List<OfferEntity> _generateFakeOffers({
    required int startIndex,
    required int count,
    String? merchantId,
  }) {
    final titles = [
      'Summer Sale',
      'Weekend Special',
      'Buy 2 Get 1 Free',
      'Flash Deal',
      'Happy Hour',
      'Lunch Combo',
      'Family Bundle',
      'New Customer Offer',
    ];
    return List.generate(count, (i) {
      final idx = startIndex + i;
      final titleIdx = idx % titles.length;
      return OfferEntity(
        id: 'offer_${idx + 1}',
        shortDescription: '${titles[titleIdx]} - Short desc',
        longDescription:
            'Long description for ${titles[titleIdx]}. Valid for limited time.',
        products: _fakeProductsForOffer(idx),
        startDate: DateTime.now().subtract(Duration(days: idx % 30)),
        endDate: DateTime.now().add(Duration(days: 7 + (idx % 14))),
        discountType: idx % 2 == 0 ? 'PERCENTAGE' : 'VALUE',
        discountValue: idx % 2 == 0 ? 15.0 : 500,
      );
    });
  }

  List<ProductEntity> _fakeProductsForOffer(int seed) {
    return List.generate(2, (i) {
      final id = seed * 10 + i;
      return ProductEntity(
        id: 'product_$id',
        name: 'Product $id',
        description: 'Description',
        shortDescription: 'Short',
        price: 1000 + id * 100,
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
            id: id,
            url: 'https://picsum.photos/seed/$id/400/400',
            mobileUrl: 'https://picsum.photos/seed/$id/300/300',
            thumbnailUrl: 'https://picsum.photos/seed/$id/150/150',
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
