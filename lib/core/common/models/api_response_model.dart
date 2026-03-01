/// API response model matching Postman shape: statusCode, message, data.
/// Supports both camelCase (statusCode) and snake_case (status_code) from API.
class ApiResponseModel<T> {
  final int? statusCode;
  final String? message;
  final T? data;

  ApiResponseModel({
    this.statusCode,
    this.message,
    this.data,
  });

  bool get isSuccess =>
      statusCode == 200 || statusCode == 201;

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final code = json['statusCode'] as int? ?? json['status_code'] as int?;
    return ApiResponseModel<T>(
      statusCode: code,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}
