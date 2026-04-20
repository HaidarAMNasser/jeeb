import 'dart:convert';

import 'package:dio/dio.dart';

abstract class PayAdminRemoteDataSource {
  Future<void> submitMediatorPaymentProof({
    required List<String> orderIds,
    required String receiptImagePath,
  });
}

/// Placeholder multipart upload — replace [PayAdminRemoteDataSourceImpl._placeholderUrl] when backend is ready.
class PayAdminRemoteDataSourceImpl implements PayAdminRemoteDataSource {
  PayAdminRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// Fake endpoint that accepts multipart (replace with real API path).
  static const String placeholderUrl = 'https://httpbin.org/post';

  @override
  Future<void> submitMediatorPaymentProof({
    required List<String> orderIds,
    required String receiptImagePath,
  }) async {
    final file = await MultipartFile.fromFile(
      receiptImagePath,
      filename: receiptImagePath.split(RegExp(r'[\\/]')).last,
    );
    final form = FormData.fromMap({
      'receipt': file,
      'orderIds': jsonEncode(orderIds),
    });
    await _dio.post<void>(
      placeholderUrl,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }
}
