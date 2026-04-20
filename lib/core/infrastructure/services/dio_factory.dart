import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../../config/app_config.dart';
import '../../presentation/routes/navigation_service.dart';
import '../../presentation/routes/routes.dart';
import '../../common/utils/toast_util.dart';
import '../../presentation/localization/app_translation.dart';
import 'dio_cache_interceptor.dart';
import 'storage_service.dart';
// import 'package:chucker_flutter/chucker_flutter.dart';

const String accept = "Accept";
const String acceptEncoding = "Accept-Encoding";
const String applicationJson = "application/json";
const String authorization = "Authorization";
const String connection = "Connection";
const String keepAlive = "keep-alive";
const String httpAcceptLanguage = "lang";
const String isMobile = "is_mobile";

class DioFactory {
  final StorageService _storageService;
  final NavigationService _navigationService;

  DioFactory(this._storageService, this._navigationService);

  Future<Dio> getDio() async {
    Dio dio = Dio();
    final String lang = _storageService.getAppLanguage();
    await _storageService.getUserToken();

    Map<String, dynamic> headers = {
      accept: applicationJson,
      acceptEncoding: 'gzip, deflate, br, zstd',
      connection: keepAlive,
      // Don't send Authorization in BaseOptions to avoid early wrong cache
      httpAcceptLanguage: lang,
      isMobile: true,
    };

    dio.options = BaseOptions(
      baseUrl: AppConfig.baseUrl,
      headers: headers,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      persistentConnection: true,
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) {
        if (status == null) return false;
        if (status == 401 || status == 403 || status == 404) return false;
        return status < 500;
      },
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);
      client.idleTimeout = const Duration(seconds: 90);
      client.maxConnectionsPerHost = 6;
      return client;
    };

    final cacheInterceptor = CacheInterceptor(
      defaultCacheDuration: const Duration(minutes: 5),
    );

    // Chucker
    // dio.interceptors.add(ChuckerDioInterceptor());
    dio.interceptors.add(
      AppInterceptors(_storageService, _navigationService, cacheInterceptor),
    );
    dio.interceptors.add(cacheInterceptor);

    return dio;
  }
}

class AppInterceptors extends Interceptor {
  final StorageService _storageService;
  final NavigationService _navigationService;
  final CacheInterceptor _cacheInterceptor;

  AppInterceptors(
    this._storageService,
    this._navigationService,
    this._cacheInterceptor,
  );

  DateTime? requestStartTime;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    requestStartTime = DateTime.now();

    final String lang = _storageService.getAppLanguage();
    await _storageService.getUserToken();
    options.headers[accept] = applicationJson;
    options.headers[acceptEncoding] = 'gzip, deflate, br, zstd';
    options.headers[connection] = keepAlive;
    options.headers[httpAcceptLanguage] = lang;
    options.headers[isMobile] = true;

    final tokenForRequest = await _storageService.getUserToken();
    if (tokenForRequest.isNotEmpty) {
      options.headers[authorization] = "Bearer $tokenForRequest";
    }
    if (kDebugMode) {
      print('HTTP Request: ${options.method} ${options.path}');
      print('Headers: ${options.headers}');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (kDebugMode) {
      print('HTTP Error: status=$status, path=${err.requestOptions.path}');
      print('Response data: ${err.response?.data}');
    }
    // 401 = Unauthorized (invalid/expired token) → clear session and redirect to login.
    // 403 = Forbidden (valid token but no permission for this resource) → do NOT clear session.
    if (status == 401) {
      final isAuthRequest =
          err.requestOptions.path.contains('login') ||
          err.requestOptions.path.contains('Login') ||
          err.requestOptions.path.contains('Auth_general') ||
          err.requestOptions.path.contains('auth/login') ||
          err.requestOptions.path.contains('auth/register');

      if (!isAuthRequest) {
        _cacheInterceptor.clearCache();
        _storageService.clearStorage(clearAuthParams: true).then((_) {
          customToast(msg: AppTranslation.sessionExpired);
          _navigationService.pushNamedAndRemoveUntil(Routes.login);
        });
      }
      return handler.next(err);
    }
    if (status == 403) {
      // Forbidden: token is valid but user has no permission for this endpoint. Do not logout.
      return handler.next(err);
    }
    if (err.response?.statusCode == 404) {
      // Handle not found errors if needed
    }

    return super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (requestStartTime != null && AppConfig.enableLogging) {
      final duration = DateTime.now().difference(requestStartTime!);
      print(
        "⏱️ ${response.requestOptions.path} took: ${duration.inMilliseconds}ms",
      );

      if (duration.inSeconds > 3) {
        print(
          "⚠️ SLOW REQUEST: ${response.requestOptions.path} - ${duration.inSeconds}s",
        );
      }
    }

    return super.onResponse(response, handler);
  }
}
