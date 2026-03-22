import 'package:jeeb_app/core/common/models/pagination_model.dart';
import 'package:jeeb_app/features/category/list_category/data/models/category_model.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';
import 'package:jeeb_app/features/offer/list_offer/data/models/offer_model.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_image_model.dart';

class SearchResultModel {
  static dynamic fromJson(Map<String, dynamic> json) {
    try {
      final type = json['type']?.toString().toLowerCase();
      if (type == null) return null;

      if (type == 'merchant' ||
          type == 'merchants' ||
          type == 'restaurant' ||
          type == 'user') {
        final nameData = json['name'] ?? json['firstName'] ?? json['lastName'];
        String name = '';
        if (nameData is Map) {
          name = (nameData['ar'] ?? nameData['en'] ?? '').toString();
        } else {
          name = nameData?.toString() ?? '';
        }

        String? imageUrl;
        if (json['image'] != null) {
          if (json['image'] is String) {
            imageUrl = json['image']
                .toString()
                .trim()
                .replaceAll('`', '')
                .replaceAll(' ', '');
          } else if (json['image'] is Map) {
            final imageMap = json['image'] as Map;
            imageUrl =
                (imageMap['url'] ??
                        imageMap['mobileUrl'] ??
                        imageMap['thumbnailUrl'])
                    ?.toString();
          }
        }

        return MerchantModel(
          id: (json['merchantId'] ?? json['id'] ?? '').toString(),
          firstName: name,
          lastName: json['lastName']?.toString() ?? '',
          email: json['email']?.toString() ?? '',
          phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
          image: imageUrl != null
              ? MerchantImageModel(
                  id: 0,
                  url: imageUrl,
                  mobileUrl: imageUrl,
                  thumbnailUrl: imageUrl,
                  isMain: true,
                )
              : null,
        );
      }

      switch (type) {
        case 'product':
          final nameData = json['name'] ?? json['productName'];
          String name = '';
          if (nameData is Map) {
            name = (nameData['ar'] ?? nameData['en'] ?? '').toString();
          } else {
            name = nameData?.toString() ?? '';
          }

          int price = 0;
          if (json['price'] is num) {
            price = (json['price'] as num).toInt();
          } else if (json['price'] is String) {
            price = int.tryParse(json['price'] as String) ?? 0;
          }

          String? imageUrl;
          if (json['image'] != null) {
            if (json['image'] is String) {
              imageUrl = json['image']
                  .toString()
                  .trim()
                  .replaceAll('`', '')
                  .replaceAll(' ', '');
            } else if (json['image'] is Map) {
              final imageMap = json['image'] as Map;
              imageUrl =
                  (imageMap['url'] ??
                          imageMap['mobileUrl'] ??
                          imageMap['thumbnailUrl'])
                      ?.toString();
            }
          }

          return ProductModel(
            id: (json['id'] ?? json['productId'] ?? '').toString(),
            name: name,
            price: price,
            isFavorite: json['isFavorite'] as bool?,
            images: imageUrl != null
                ? [
                    ProductImageModel(
                      id: 0,
                      url: imageUrl,
                      mobileUrl: imageUrl,
                      thumbnailUrl: imageUrl,
                      isMain: true,
                      displayOrder: 1,
                    ),
                  ]
                : [],
            merchantId: (json['merchantId'] ?? json['restaurantId'])
                ?.toString(),
            categoryId: (json['categoryId'] ?? json['id'])?.toString(),
          );
        case 'offer':
          final nameData = json['name'] ?? json['title'];
          String name = '';
          if (nameData is Map) {
            name = (nameData['ar'] ?? nameData['en'] ?? '').toString();
          } else {
            name = nameData?.toString() ?? '';
          }

          String? imageUrl;
          if (json['image'] != null) {
            if (json['image'] is String) {
              imageUrl = json['image']
                  .toString()
                  .trim()
                  .replaceAll('`', '')
                  .replaceAll(' ', '');
            } else if (json['image'] is Map) {
              final imageMap = json['image'] as Map;
              imageUrl =
                  (imageMap['url'] ??
                          imageMap['mobileUrl'] ??
                          imageMap['thumbnailUrl'])
                      ?.toString();
            }
          }

          return OfferModel(
            id: (json['id'] ?? json['offerId'] ?? '').toString(),
            name: name,
            discountValue: (json['discountValue'] as num?)?.toDouble(),
            discountType: json['discountType']?.toString(),
            image: imageUrl,
            merchant: (json['merchantId'] ?? json['merchant']?['id']) != null
                ? MerchantModel(
                    id: (json['merchantId'] ?? json['merchant']?['id'])
                        .toString(),
                    firstName:
                        (json['merchantName'] ??
                                json['merchant']?['name'] ??
                                '')
                            .toString(),
                    lastName: '',
                    email: '',
                    phone: '',
                  )
                : null,
          );
        case 'category':
          final nameData = json['name'];
          String name = '';
          if (nameData is Map) {
            name = (nameData['ar'] ?? nameData['en'] ?? '').toString();
          } else {
            name = nameData?.toString() ?? '';
          }

          String? imageUrl;
          if (json['image'] != null) {
            if (json['image'] is String) {
              imageUrl = json['image']
                  .toString()
                  .trim()
                  .replaceAll('`', '')
                  .replaceAll(' ', '');
            } else if (json['image'] is Map) {
              final imageMap = json['image'] as Map;
              imageUrl =
                  (imageMap['url'] ??
                          imageMap['mobileUrl'] ??
                          imageMap['thumbnailUrl'])
                      ?.toString();
            }
          }

          return CategoryModel(
            id: (json['id'] ?? json['categoryId'] ?? '').toString(),
            name: name,
            imageUrl: imageUrl,
          );
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
}

class SearchResponseModel {
  final List<dynamic> results;
  final PaginationModel pagination;

  SearchResponseModel({required this.results, required this.pagination});

  factory SearchResponseModel.fromJson(dynamic json) {
    print('SearchResponseModel: raw json = $json');
    List<dynamic> dataList = [];
    Map<String, dynamic>? paginationMap;

    if (json is Map) {
      // Dio might return _Map<Object?, Object?>, so we convert to Map<dynamic, dynamic>
      final Map<dynamic, dynamic> responseMap = json;
      final dynamic rawData = responseMap['data'];
      print('SearchResponseModel: rawData type = ${rawData.runtimeType}');

      if (rawData is Map) {
        final Map<dynamic, dynamic> dataMap = rawData;
        print('SearchResponseModel: dataMap keys = ${dataMap.keys}');

        // 1. Handle grouped response: products, offers, merchants
        final dynamic productsObj = dataMap['products'];
        if (productsObj is Map) {
          final dynamic productsData = productsObj['data'];
          if (productsData is List) {
            print('SearchResponseModel: found ${productsData.length} products');
            for (var item in productsData) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                map['type'] = 'product';
                dataList.add(map);
              }
            }
          }
        }

        final dynamic offersObj = dataMap['offers'];
        if (offersObj is Map) {
          final dynamic offersData = offersObj['data'];
          if (offersData is List) {
            print('SearchResponseModel: found ${offersData.length} offers');
            for (var item in offersData) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                map['type'] = 'offer';
                dataList.add(map);
              }
            }
          }
        }

        final dynamic merchantsObj = dataMap['merchants'];
        if (merchantsObj is Map) {
          final dynamic merchantsData = merchantsObj['data'];
          if (merchantsData is List) {
            print(
              'SearchResponseModel: found ${merchantsData.length} merchants',
            );
            for (var item in merchantsData) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                map['type'] = 'merchant';
                dataList.add(map);
              }
            }
          }
        }
      }

      // 2. Fallback for flat response structure if dataList is still empty
      if (dataList.isEmpty) {
        print('SearchResponseModel: dataList is empty, trying fallbacks');
        if (rawData is List) {
          dataList = rawData;
        } else if (rawData is Map) {
          final dynamic nestedData = (rawData as Map)['data'];
          if (nestedData is List) {
            dataList = nestedData;
          }
        } else if (responseMap['results'] is List) {
          dataList = responseMap['results'] as List;
        } else if (responseMap.containsKey('type')) {
          dataList = [responseMap];
        }
      }

      // 3. Determine pagination
      final dynamic rawPagination =
          responseMap['pagination'] ??
          (rawData is Map ? (rawData as Map)['pagination'] : null);
      if (rawPagination is Map) {
        paginationMap = Map<String, dynamic>.from(rawPagination);
      }
    } else if (json is List) {
      dataList = json;
    }

    print('SearchResponseModel: final dataList size = ${dataList.length}');

    final results = dataList
        .map((item) {
          try {
            if (item is Map) {
              final result = SearchResultModel.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (result == null) {
                print(
                  'SearchResponseModel: SearchResultModel.fromJson returned null for item: $item',
                );
              }
              return result;
            }
          } catch (e) {
            print('SearchResponseModel: Error parsing item $item: $e');
          }
          return null;
        })
        .where((element) => element != null)
        .toList();

    print('SearchResponseModel: final results size = ${results.length}');
    for (var res in results) {
      print('SearchResponseModel: result item type = ${res.runtimeType}');
    }

    PaginationModel pagination;
    try {
      if (paginationMap != null) {
        pagination = PaginationModel.fromJson(paginationMap);
      } else {
        throw Exception("No pagination");
      }
    } catch (e) {
      pagination = PaginationModel(
        total: results.length,
        page: 1,
        limit: 10,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    }

    return SearchResponseModel(results: results, pagination: pagination);
  }
}
