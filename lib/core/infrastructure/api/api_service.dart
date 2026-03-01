import 'package:dio/dio.dart';

part 'api_service_impl.dart';

/// API Service Client Interface
/// Defines all API endpoints for the application
abstract class AppApiServiceClient {
  factory AppApiServiceClient({required Dio dio, required String baseUrlApi}) =
      _AppApiServiceClientImpl;

  // Authentication endpoints
  @POST("apiAdmin/Auth_general/login")
  Future<Response> loginWithPhone(
    @Field('phone') String phone,
    @Field('password') String password,
    @Field('is_mobile_pass') bool directLogin,
    @Field('phone_code_id') int phoneCodeId,
  );

  @POST("apiAdmin/Auth_general/login")
  Future<Response> loginWithEmail(
    @Field('email') String email,
    @Field('password') String password,
    @Field('is_mobile_pass') bool directLogin,
  );

  @POST("auth/register")
  Future<Response> register(Map<String, dynamic> body);

  @POST("auth/verify")
  Future<Response> verify({required String email, required String otp});

  @POST("auth/resend-otp")
  Future<Response> resendOtp({required String email});

  @POST("auth/forgot-password")
  Future<Response> forgotPassword({required String email});

  @POST("auth/reset-password")
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  });

  @GET("auth/profile")
  Future<Response> getProfile();

  @PATCH("auth/profile")
  Future<Response> updateProfile(Map<String, dynamic> body);

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

  // Add more endpoints as needed
  // Example:
  // @GET("apiAdmin/User/all")
  // Future<Response> getUsers(@Queries() Map<String, dynamic> queries);
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
