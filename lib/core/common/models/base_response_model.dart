import 'pagination_model.dart';

class BaseResponseModel<T> {
  bool? success;
  int? status;
  String? message;
  int? statusCode;
  T? data;
  PaginationModel? pagination;

  BaseResponseModel({
    required this.success,
    required this.message,
    required this.status,
    required this.statusCode,
    required this.data,
    this.pagination,
  });

  factory BaseResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return BaseResponseModel<T>(
      success: json['success'] as bool?,
      status: json['status'] as int?,
      message: json['message'] as String?,
      statusCode: (json['statusCode'] ?? json['status_code']) as int?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Object Function(T) toJsonT) {
    return {
      'success': success,
      'status': status,
      'message': message,
      'status_code': statusCode,
      'data': data != null ? toJsonT(data as T) : null,
      'pagination': pagination?.toJson(),
    };
  }
}

