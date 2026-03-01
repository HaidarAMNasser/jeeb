/// API Response Model for the new backend structure
/// {
///   "statusCode": 200,
///   "message": "...",
///   "data": {...},
///   "timestamp": "...",
///   "path": "..."
/// }
class ApiResponseModel<T> {
  final int statusCode;
  final String message;
  final T? data;
  final String? timestamp;
  final String? path;

  ApiResponseModel({
    required this.statusCode,
    required this.message,
    this.data,
    this.timestamp,
    this.path,
  });

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponseModel<T>(
      statusCode: json['statusCode'] as int? ?? 200,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] as String?,
      path: json['path'] as String?,
    );
  }

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

