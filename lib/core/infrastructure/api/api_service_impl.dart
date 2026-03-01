part of 'api_service.dart';

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
      'is_mobile_pass': directLogin,
      'phone_code_id': phoneCodeId,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'apiAdmin/Auth_general/login',
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
      'is_mobile_pass': directLogin,
    };

    final result = await dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'apiAdmin/Auth_general/login',
              queryParameters: queryParameters,
              data: data,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );

    return result;
  }

  @override
  Future<Response> register(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    return dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'POST', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/register',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
  }

  @override
  Future<Response> verify({required String email, required String otp}) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email, 'otp': otp};

    return dio.fetch<Map<String, dynamic>>(
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
  }

  @override
  Future<Response> resendOtp({required String email}) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email};

    return dio.fetch<Map<String, dynamic>>(
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
  }

  @override
  Future<Response> forgotPassword({required String email}) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email};

    return dio.fetch<Map<String, dynamic>>(
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
  }

  @override
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};
    final data = {'email': email, 'otp': otp, 'password': password};

    return dio.fetch<Map<String, dynamic>>(
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
  }

  @override
  Future<Response> getProfile() async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    return dio.fetch<Map<String, dynamic>>(
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
  }

  @override
  Future<Response> updateProfile(Map<String, dynamic> body) async {
    const extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final headers = <String, dynamic>{};

    return dio.fetch<Map<String, dynamic>>(
      _setStreamType(
        Options(method: 'PATCH', headers: headers, extra: extra)
            .compose(
              dio.options,
              'auth/profile',
              queryParameters: queryParameters,
              data: body,
            )
            .copyWith(baseUrl: baseUrlApi),
      ),
    );
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
}
