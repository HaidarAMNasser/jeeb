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
}

