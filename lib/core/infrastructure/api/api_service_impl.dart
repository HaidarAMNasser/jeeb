part of 'api_service.dart';

/// All requests use the shared [dio] instance. The access token (Authorization header)
/// is added automatically by [AppInterceptors] in dio_factory.dart for every request
/// when the user is logged in (token from storage). No need to set it per endpoint here.
class _AppApiServiceClientImpl implements AppApiServiceClient {
  _AppApiServiceClientImpl({required this.dio, required this.baseUrlApi});

  final Dio dio;
  final String baseUrlApi;

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  @override
  Future<Response> loginWithPhone(
    String phone,
    String password,
    bool directLogin,
    int phoneCodeId,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {
      'phone': phone,
      'password': password,
      // 'is_mobile_pass': directLogin,
      'phone_code_id': phoneCodeId,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/login',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> loginWithEmail(
    String email,
    String password,
    bool directLogin,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {
      'email': email,
      'password': password,
      // 'is_mobile_pass': directLogin,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/login',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> register(
    String firstName,
    String lastName,
    String email,
    String password,
    String phone,
    String role,
    int? countryId,
    int? cityId,
    double? latitude,
    double? longitude,
    String notificationChannel,
    String? address,
    String? birthday,
    MultipartFile? image,
    List<MultipartFile>? images,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
      'notificationChannel': notificationChannel,
    };
    if (countryId != null) data['countryId'] = countryId;
    if (cityId != null) data['cityId'] = cityId;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (address != null) data['address'] = address;
    if (birthday != null && birthday.isNotEmpty) {
      data['birthday'] = birthday;
    }

    final hasFiles = image != null || (images != null && images.isNotEmpty);
    final dynamic requestData;
    final Options options;

    if (hasFiles) {
      // Multipart: single Map → FormData. Do NOT set Content-Type; Dio sets multipart + boundary.
      final formMap = <String, dynamic>{
        ...data.map((k, v) => MapEntry(k, v is String ? v : v.toString())),
      };
      if (image != null) formMap['image'] = image;
      if (images != null && images.isNotEmpty) {
        for (var i = 0; i < images.length; i++) {
          formMap['images[$i]'] = images[i];
        }
      }
      requestData = FormData.fromMap(formMap);
      options = Options(method: 'POST', headers: headers, extra: extra);
    } else {
      // No files → JSON only. One object, numeric types for countryId, latitude, longitude.
      requestData = data;
      options = Options(
        method: 'POST',
        contentType: Headers.jsonContentType,
        headers: headers,
        extra: extra,
      );
    }

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        options
            .compose(
              dio.options,
              'auth/register',
              queryParameters: queryParameters,
              data: requestData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> verify(String email, String otp) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email, 'otp': otp};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/verify',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> resendOtp(String email) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/resend-otp',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> forgotPassword(String email) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/forgot-password',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> resetPassword(
    String email,
    String otp,
    String password,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email, 'otp': otp, 'password': password};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/reset-password',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getProfile() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/profile',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    MultipartFile? image,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final formData = FormData();
    if (firstName != null)
      formData.fields.add(MapEntry('firstName', firstName));
    if (lastName != null) formData.fields.add(MapEntry('lastName', lastName));
    if (phone != null) formData.fields.add(MapEntry('phone', phone));
    if (countryId != null)
      formData.fields.add(MapEntry('countryId', countryId.toString()));
    if (cityId != null)
      formData.fields.add(MapEntry('cityId', cityId.toString()));
    if (address != null) formData.fields.add(MapEntry('address', address));
    if (latitude != null)
      formData.fields.add(MapEntry('latitude', latitude.toString()));
    if (longitude != null)
      formData.fields.add(MapEntry('longitude', longitude.toString()));
    if (isActive != null)
      formData.fields.add(MapEntry('isActive', isActive.toString()));
    if (image != null) {
      formData.files.add(MapEntry('image', image));
    }

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/profile',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> logout() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/logout',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateDeviceToken({
    required String token,
    required String platform,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{'firebaseToken': token};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/firebase-token',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getCategories(int? page, int? limit) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'categories',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> addCategory(String name) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'name': name};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'apiAdmin/Category/create',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getProducts(
    int? page,
    int? limit,
    String? search,
    String? categoryId,
    String? restaurantId,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    String? type,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty)
      queryParameters['categoryId'] = categoryId;
    if (restaurantId != null && restaurantId.isNotEmpty && restaurantId != '0')
      queryParameters['merchantId'] = restaurantId;
    if (minPrice != null) queryParameters['minPrice'] = minPrice;
    if (maxPrice != null) queryParameters['maxPrice'] = maxPrice;
    if (minRating != null) queryParameters['minRating'] = minRating;
    if (type != null && type.isNotEmpty) queryParameters['type'] = type;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'products', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getFavorites({int? page, int? limit}) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'favorites', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
    return result;
  }

  @override
  Future<Response> toggleFavorites({
    List<int>? restaurants,
    List<int>? products,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{};
    if (restaurants != null && restaurants.isNotEmpty)
      data['restaurants'] = restaurants;
    if (products != null && products.isNotEmpty) data['products'] = products;

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'favorites/toggle',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getCart() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'cart', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
    return result;
  }

  @override
  Future<Response> createCart(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'cart',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
    return result;
  }

  @override
  Future<Response> updateCart(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'cart',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
    return result;
  }

  @override
  Future<Response> clearCart() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(dio.options, 'cart', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
    return result;
  }

  @override
  Future<Response> createReview({
    required String entityType,
    required int entityId,
    required int rating,
    required String comment,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{
      'entityType': entityType,
      'entityId': entityId,
      'rating': rating,
      'comment': comment,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'reviews',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getReview(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'reviews/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateReview(
    String id, {
    int? rating,
    String? comment,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'reviews/$id',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteReview(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(
              dio.options,
              'reviews/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getProductDetails(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> createProduct(FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{'Content-Type': 'multipart/form-data'};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateProduct(String id, FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{'Content-Type': 'multipart/form-data'};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products/$id',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteProduct(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> confirmProduct(String id, double newPrice) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = <String, dynamic>{'newPrice': newPrice};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products/$id/confirm',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteProductImage(String imageId) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(
              dio.options,
              'products/images/$imageId',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> confirmDeliveryMan(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries/$id/confirm',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getCountries(int? page, int? limit) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'countries', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getCities(int countryId, int? page, int? limit) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{'countryId': countryId};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'cities', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getSettings() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'settings', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getMerchants({
    int? page,
    int? limit,
    String? search,
    int? countryId,
    int? cityId,
    bool? isActive,
    String? type,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (countryId != null) queryParameters['countryId'] = countryId;
    if (cityId != null) queryParameters['cityId'] = cityId;
    if (isActive != null) queryParameters['isActive'] = isActive;
    if (type != null && type.isNotEmpty) queryParameters['type'] = type;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/merchants',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getMerchantDetails(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/merchants/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> createMerchant(FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/merchants',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateMerchant(String id, FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/merchants/$id',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteMerchant(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/merchants/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getMerchantReviews({
    required String merchantId,
    int? page,
    int? limit,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'merchants/$merchantId/reviews',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getDeliveryMen({
    int? page,
    int? limit,
    String? search,
    bool? isOnline,
    int? officeOwnerId,
    int? countryId,
    int? cityId,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;
    if (isOnline != null) queryParameters['isOnline'] = isOnline;
    if (officeOwnerId != null) queryParameters['officeOwnerId'] = officeOwnerId;
    if (countryId != null) queryParameters['countryId'] = countryId;
    if (cityId != null) queryParameters['cityId'] = cityId;
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getDeliveryManDetails(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> createDeliveryMan(FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateDeliveryMan(String id, FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries/$id',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteDeliveryMan(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'DELETE', headers: headers, extra: extra)
            .compose(
              dio.options,
              'users/deliveries/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getOrders({
    int? page,
    int? limit,
    String? search,
    String? status,
    String? ownerId,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParameters['ownerId'] = ownerId;
    }
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'orders', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> createOrder(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> calculateDeliveryCost(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'distance/calculate-delivery-cost',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getOrderDetails(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> acceptDelivery(String id, int deliveryTime) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'deliveryTime': deliveryTime};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/accept-delivery',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> confirmPickup(String id, String reason) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'reason': reason};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/picked-up',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> markOnTheWay(String id, String reason) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'reason': reason};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/on-the-way',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> markAsDelivered(
    String id,
    String reason,
    double lat,
    double lng,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {
      'reason': reason,
      'finalLocation': {'lat': lat, 'lng': lng},
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/delivered',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> markOrdersPaid(FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/paid',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> rejectDelivery(String id, String reason) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'reason': reason};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/reject-delivery',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> completeOrder(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/complete',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> cancelOrder(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'orders/$id/cancel',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getOffers({
    int? page,
    int? limit,
    String? restaurantId,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    if (page != null) queryParameters['page'] = page;
    if (limit != null) queryParameters['limit'] = limit;
    if (restaurantId != null && restaurantId.isNotEmpty) {
      queryParameters['merchantId'] = restaurantId;
    }
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(dio.options, 'offers', queryParameters: queryParameters)
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> getOfferDetails(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'offers/$id',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> createOffer(FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'offers',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateOffer(String id, FormData formData) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'offers/$id',
              queryParameters: queryParameters,
              data: formData,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> deleteOffer(String id) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'offers/$id/delete',
              queryParameters: queryParameters,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> search({
    required String query,
    int? page,
    int? limit,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      'q': query,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
    final headers = <String, dynamic>{};
    const data = <String, dynamic>{};

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'GET', headers: headers, extra: extra)
            .compose(
              dio.options,
              'search',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> updateDeliveryTrackingLocation(
    int orderId,
    double lat,
    double lng,
    int timestamp,
    double speed,
  ) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {
      'orderId': orderId,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp,
      'speed': speed,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'tracking/update-location',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }
}
