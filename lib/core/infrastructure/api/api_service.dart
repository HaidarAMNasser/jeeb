import 'package:dio/dio.dart';

part 'api_service_impl.dart';

/// API Service Client Interface
/// Defines all API endpoints for the application
abstract class AppApiServiceClient {
  factory AppApiServiceClient({required Dio dio, required String baseUrlApi}) =
      _AppApiServiceClientImpl;

  // Favorites endpoints
  @GET("favorites")
  Future<Response> getFavorites({
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  @POST("favorites/toggle")
  Future<Response> toggleFavorites({
    List<int>? restaurants,
    List<int>? products,
  });

  // Basket / Cart endpoints
  @GET("cart")
  Future<Response> getCart();

  @POST("cart")
  Future<Response> createCart(Map<String, dynamic> body);

  @PATCH("cart")
  Future<Response> updateCart(Map<String, dynamic> body);

  @DELETE("cart")
  Future<Response> clearCart();

  // Reviews endpoints (product/order reviews by customer)
  @POST("reviews")
  Future<Response> createReview({
    required String entityType,
    required int entityId,
    required int rating,
    required String comment,
  });

  @GET("reviews/{id}")
  Future<Response> getReview(@Path('id') String id);

  @PATCH("reviews/{id}")
  Future<Response> updateReview(
    @Path('id') String id, {
    int? rating,
    String? comment,
  });

  @DELETE("reviews/{id}")
  Future<Response> deleteReview(@Path('id') String id);

  // Authentication endpoints
  @POST("auth/login")
  Future<Response> loginWithPhone(
    @Field('phone') String phone,
    @Field('password') String password,
    @Field('is_mobile_pass') bool directLogin,
    @Field('phone_code_id') int phoneCodeId,
  );

  @POST("auth/login")
  Future<Response> loginWithEmail(
    @Field('email') String email,
    @Field('password') String password,
    @Field('is_mobile_pass') bool directLogin,
  );

  @POST("auth/register")
  Future<Response> register(
    @Field('firstName') String firstName,
    @Field('lastName') String lastName,
    @Field('email') String email,
    @Field('password') String password,
    @Field('phone') String phone,
    @Field('role') String role,
    @Field('countryId') int? countryId,
    @Field('cityId') int? cityId,
    @Field('latitude') double? latitude,
    @Field('longitude') double? longitude,
    @Field('notificationChannel') String notificationChannel,
    @Field('address') String? address,
    @Field('birthday') String? birthday,
    MultipartFile? image,
    List<MultipartFile>? images,
  );

  @POST("auth/verify")
  Future<Response> verify(
    @Field('email') String email,
    @Field('otp') String otp,
  );

  @POST("auth/resend-otp")
  Future<Response> resendOtp(@Field('email') String email);

  @POST("auth/forgot-password")
  Future<Response> forgotPassword(@Field('email') String email);

  @POST("auth/reset-password")
  Future<Response> resetPassword(
    @Field('email') String email,
    @Field('otp') String otp,
    @Field('password') String password,
  );

  @GET("auth/profile")
  Future<Response> getProfile();

  @GET("settings")
  Future<Response> getSettings();

  @PATCH("auth/profile")
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
  });

  @POST("auth/logout")
  Future<Response> logout();

  @POST("auth/firebase-token")
  Future<Response> updateDeviceToken({
    @Field('token') required String token,
    @Field('platform') required String platform,
  });

  // Category endpoints
  @GET("apiAdmin/Category/all")
  Future<Response> getCategories(
    @Query('page') int? page,
    @Query('limit') int? limit,
  );

  @POST("apiAdmin/Category/create")
  Future<Response> addCategory(@Field('name') String name);

  // Product endpoints
  @GET("products")
  Future<Response> getProducts(
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('categoryId') String? categoryId,
    @Query('restaurantId') String? restaurantId,
    @Query('minPrice') double? minPrice,
    @Query('maxPrice') double? maxPrice,
    @Query('minRating') int? minRating,
  );

  @GET("products/{id}")
  Future<Response> getProductDetails(@Path('id') String id);

  @POST("products")
  Future<Response> createProduct(FormData formData);

  @PATCH("products/{id}")
  Future<Response> updateProduct(@Path('id') String id, FormData formData);

  /// Confirm product and set final price so it becomes visible to clients.
  @POST("products/{id}/confirm")
  Future<Response> confirmProduct(
    @Path('id') String id,
    @Field('newPrice') double newPrice,
  );

  @DELETE("products/{id}")
  Future<Response> deleteProduct(@Path('id') String id);

  @DELETE("products/images/{imageId}")
  Future<Response> deleteProductImage(@Path('imageId') String imageId);

  // Countries & Cities endpoints
  @GET("countries")
  Future<Response> getCountries(
    @Query('page') int? page,
    @Query('limit') int? limit,
  );

  @GET("cities")
  Future<Response> getCities(
    @Query('countryId') int countryId,
    @Query('page') int? page,
    @Query('limit') int? limit,
  );

  // Merchant endpoints
  @GET("users/merchants")
  Future<Response> getMerchants({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('countryId') int? countryId,
    @Query('cityId') int? cityId,
    @Query('isActive') bool? isActive,
  });

  @GET("users/merchants/{id}")
  Future<Response> getMerchantDetails(@Path('id') String id);

  @POST("users/merchants")
  Future<Response> createMerchant(FormData formData);

  @PATCH("users/merchants/{id}")
  Future<Response> updateMerchant(@Path('id') String id, FormData formData);

  @DELETE("users/merchants/{id}")
  Future<Response> deleteMerchant(@Path('id') String id);

  // Merchant Review endpoints
  @GET("merchants/{merchantId}/reviews")
  Future<Response> getMerchantReviews({
    @Path('merchantId') required String merchantId,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });

  // Delivery endpoints
  @GET("users/deliveries")
  Future<Response> getDeliveryMen({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('isOnline') bool? isOnline,
    @Query('officeOwnerId') int? officeOwnerId,
    @Query('countryId') int? countryId,
    @Query('cityId') int? cityId,
  });

  @GET("users/deliveries/{id}")
  Future<Response> getDeliveryManDetails(@Path('id') String id);

  @POST("users/deliveries")
  Future<Response> createDeliveryMan(FormData formData);

  @PATCH("users/deliveries/{id}")
  Future<Response> updateDeliveryMan(@Path('id') String id, FormData formData);

  @DELETE("users/deliveries/{id}")
  Future<Response> deleteDeliveryMan(@Path('id') String id);

  @POST("users/deliveries/{id}/confirm")
  Future<Response> confirmDeliveryMan(@Path('id') String id);

  // Order endpoints
  @GET("orders")
  Future<Response> getOrders({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('search') String? search,
    @Query('status') String? status,
    @Query('ownerId') String? ownerId,
  });

  @POST("orders")
  Future<Response> createOrder(Map<String, dynamic> body);

  @GET("orders/{id}")
  Future<Response> getOrderDetails(@Path('id') String id);

  @POST("orders/{id}/accept-delivery")
  Future<Response> acceptDelivery(
    @Path('id') String id,
    @Field('deliveryTime') int deliveryTime,
  );

  @PATCH("orders/{id}/picked-up")
  Future<Response> confirmPickup(
    @Path('id') String id,
    @Field('reason') String reason,
  );

  @PATCH("orders/{id}/delivered")
  Future<Response> markAsDelivered(
    @Path('id') String id,
    @Field('reason') String reason,
    @Field('lat') double lat,
    @Field('lng') double lng,
  );

  @POST("orders/{id}/reject-delivery")
  Future<Response> rejectDelivery(
    @Path('id') String id,
    @Field('reason') String reason,
  );

  @POST("orders/{id}/complete")
  Future<Response> completeOrder(@Path('id') String id);

  @POST("orders/{id}/cancel")
  Future<Response> cancelOrder(@Path('id') String id);

  // Offer endpoints (merchant & admin)
  @GET("offers")
  Future<Response> getOffers({
    @Query('page') int? page,
    @Query('limit') int? limit,
    @Query('restaurantId') String? restaurantId,
  });

  @GET("offers/{id}")
  Future<Response> getOfferDetails(@Path('id') String id);

  @POST("offers")
  Future<Response> createOffer(FormData formData);

  @POST("offers/{id}")
  Future<Response> updateOffer(@Path('id') String id, FormData formData);

  @POST("offers/{id}/delete")
  Future<Response> deleteOffer(@Path('id') String id);

  // Global Search endpoint
  @GET("search")
  Future<Response> search({
    @Query('q') required String query,
    @Query('page') int? page,
    @Query('limit') int? limit,
  });
}

// Annotations for API methods (simplified versions)
class POST {
  final String path;
  const POST(this.path);
}

class GET {
  final String path;
  const GET(this.path);
}

class PUT {
  final String path;
  const PUT(this.path);
}

class DELETE {
  final String path;
  const DELETE(this.path);
}

class PATCH {
  final String path;
  const PATCH(this.path);
}

class Field {
  final String name;
  const Field(this.name);
}

class Query {
  final String name;
  const Query(this.name);
}

class Queries {
  const Queries();
}

class Path {
  final String name;
  const Path(this.name);
}

class Header {
  final String name;
  const Header(this.name);
}
