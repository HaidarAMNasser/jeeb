import 'package:dio/dio.dart';
import '../errors/failure.dart';
import '../errors/exceptions.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const TimeoutFailure(
            message: 'Request timeout. Please try again.',
          );
        case DioExceptionType.badResponse:
          return _handleResponse(error.response?.statusCode, error.response?.data);
        case DioExceptionType.cancel:
          return const ServerFailure(message: 'Request cancelled.');
        case DioExceptionType.connectionError:
          return const NetworkFailure();
        default:
          return const ServerFailure(message: 'Something went wrong.');
      }
    } else if (error is ServerException) {
      return ServerFailure(message: error.message, code: error.statusCode);
    } else if (error is NetworkException) {
      return const NetworkFailure();
    } else {
      return ServerFailure(message: error.toString());
    }
  }

  static Failure _handleResponse(int? statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return const ServerFailure(message: 'Bad request.', code: 400);
      case 401:
        return const UnauthorizedFailure();
      case 403:
        return const ForbiddenFailure();
      case 404:
        return const NotFoundFailure();
      case 422:
        return ValidationFailure(
          message: _extractMessage(data) ?? 'Validation failed.',
          errors: data is Map<String, dynamic> ? data : null,
        );
      case 500:
        return const ServerFailure(message: 'Internal server error.', code: 500);
      default:
        return ServerFailure(
          message: _extractMessage(data) ?? 'Something went wrong.',
          code: statusCode,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}

