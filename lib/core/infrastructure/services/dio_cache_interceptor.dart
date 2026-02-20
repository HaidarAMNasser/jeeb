import 'dart:async';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';

class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};
  final Duration defaultCacheDuration;
  final bool enableSWR;

  CacheInterceptor({
    this.defaultCacheDuration = const Duration(minutes: 5),
    this.enableSWR = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != 'GET') {
      return handler.next(options);
    }

    // Don't cache authenticated requests
    final authHeader = (options.headers['Authorization'] ?? '').toString();
    final isAuthed = authHeader.isNotEmpty;
    if (isAuthed) {
      return handler.next(options);
    }

    final cacheKey = _generateCacheKey(options);
    final cachedEntry = _cache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired()) {
      if (AppConfig.enableLogging) {
        print('📦 Cache HIT: ${options.path}');
      }

      // Return cached result immediately
      handler.resolve(
        Response(
          requestOptions: options,
          data: cachedEntry.data,
          statusCode: 200,
          headers: Headers.fromMap({
            'x-cache': ['HIT'],
          }),
        ),
      );

      // SWR: Refresh in background without blocking UI
      if (enableSWR && !isAuthed) {
        Future.microtask(() async {
          try {
            final dio = Dio(
              BaseOptions(
                connectTimeout: options.connectTimeout,
                receiveTimeout: options.receiveTimeout,
                sendTimeout: options.sendTimeout,
                // Don't add interceptors to avoid cache loop
              ),
            );
            final resp = await dio.requestUri(
              options.uri,
              data: options.data,
              options: Options(
                method: options.method,
                headers: options.headers,
                responseType: options.responseType,
                contentType: options.contentType,
                followRedirects: options.followRedirects,
                validateStatus: (_) => true,
              ),
              onSendProgress: options.onSendProgress,
              onReceiveProgress: options.onReceiveProgress,
            );
            if (resp.statusCode == 200) {
              final bgKey = _generateCacheKey(options);
              _cache[bgKey] = CacheEntry(
                data: resp.data,
                expireTime: DateTime.now().add(defaultCacheDuration),
              );
              if (AppConfig.enableLogging) {
                print('🔄 SWR refreshed: ${options.path}');
              }
            }
          } catch (_) {
            // Ignore background refresh errors
          }
        });
      }
      return;
    }
    if (AppConfig.enableLogging) {
      print('Cache MISS: ${options.path}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      // Don't cache authenticated responses
      final authHeader =
          (response.requestOptions.headers['Authorization'] ?? '').toString();
      final isAuthed = authHeader.isNotEmpty;
      if (isAuthed) {
        return handler.next(response);
      }
      final cacheKey = _generateCacheKey(response.requestOptions);

      Duration cacheDuration = defaultCacheDuration;

      if (response.requestOptions.path.contains('/settings') ||
          response.requestOptions.path.contains('/config')) {
        cacheDuration = const Duration(hours: 1);
      }

      _cache[cacheKey] = CacheEntry(
        data: response.data,
        expireTime: DateTime.now().add(cacheDuration),
      );

      if (AppConfig.enableLogging) {
        print(
          '💾 Cached: ${response.requestOptions.path} for ${cacheDuration.inMinutes}min',
        );
      }
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Avoid using cache for authenticated requests
    final authHeader = (err.requestOptions.headers['Authorization'] ?? '')
        .toString();
    final isAuthed = authHeader.isNotEmpty;
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      clearCache();
      if (AppConfig.enableLogging) {
        print('🗑️ Cache cleared due to authentication error');
      }
      return handler.next(err);
    }

    if (!isAuthed && err.requestOptions.method.toUpperCase() == 'GET') {
      final cacheKey = _generateCacheKey(err.requestOptions);
      final cachedEntry = _cache[cacheKey];

      if (cachedEntry != null) {
        if (AppConfig.enableLogging) {
          print(
            '⚠️ Network Error - Using Stale Cache: ${err.requestOptions.path}',
          );
        }

        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: cachedEntry.data,
            statusCode: 200,
            headers: Headers.fromMap({
              'x-cache': ['STALE'],
            }),
          ),
        );
      }
    }

    return handler.next(err);
  }

  void clearCache() {
    _cache.clear();
    if (AppConfig.enableLogging) {
      print('🗑️ Cache cleared');
    }
  }

  void invalidateCache(String path) {
    _cache.removeWhere((key, value) => key.contains(path));
    if (AppConfig.enableLogging) {
      print('🗑️ Cache invalidated for: $path');
    }
  }

  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final auth = options.headers['Authorization'] ?? '';
    final lang = options.headers['lang'] ?? '';

    return '$uri|$auth|$lang';
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expireTime;

  CacheEntry({required this.data, required this.expireTime});

  bool isExpired() {
    return DateTime.now().isAfter(expireTime);
  }
}
