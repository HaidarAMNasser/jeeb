import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/data/data_sources/manage_order_remote_data_source.dart';

class ManageOrderRepository {
  final ManageOrderRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ManageOrderRepository(this._remoteDataSource, this._networkInfo);

  Either<Failure, bool> _eitherFromResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return Left(
        ErrorHandler.handle(
          DioException(
            type: DioExceptionType.badResponse,
            response: response,
            requestOptions: response.requestOptions,
          ),
        ),
      );
    }
    final envelopeFailure = ErrorHandler.failureFromEnvelopeIfAny(response.data);
    if (envelopeFailure != null) return Left(envelopeFailure);
    return const Right(true);
  }

  static const int _maxReceiptImages = 5;
  static const int _maxReceiptBytes = 5 * 1024 * 1024;

  bool _allowedReceiptPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String _fileName(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final i = normalized.lastIndexOf('/');
    return i < 0 ? normalized : normalized.substring(i + 1);
  }

  Future<Either<Failure, bool>> acceptDelivery(
    String id,
    int deliveryTime,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.acceptDelivery(id, deliveryTime);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> confirmPickup(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.confirmPickup(id, reason);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> markOnTheWay(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.markOnTheWay(id, reason);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> markAsDelivered({
    required String id,
    required String reason,
    required double lat,
    required double lng,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response =
            await _remoteDataSource.markAsDelivered(id, reason, lat, lng);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> rejectDelivery(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.rejectDelivery(id, reason);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  /// `PATCH /orders/paid` — delivery uploads 1–5 receipt images (JPEG/PNG/WebP, max 5 MB each).
  Future<Either<Failure, bool>> markOrdersPaid({
    required String orderId,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) {
      return const Left(
        ServerFailure(message: 'payment_receipt_need_one_image'),
      );
    }
    if (imagePaths.length > _maxReceiptImages) {
      return const Left(
        ServerFailure(message: 'payment_receipt_too_many_images'),
      );
    }
    final oid = int.tryParse(orderId.trim());
    if (oid == null || oid <= 0) {
      return const Left(ServerFailure(message: 'Something went wrong.'));
    }
    for (final path in imagePaths) {
      if (!_allowedReceiptPath(path)) {
        return const Left(
          ServerFailure(message: 'payment_receipt_invalid_type'),
        );
      }
      final file = File(path);
      if (!await file.exists()) {
        return const Left(ServerFailure(message: 'Something went wrong.'));
      }
      final len = await file.length();
      if (len > _maxReceiptBytes) {
        return const Left(
          ServerFailure(message: 'payment_receipt_file_too_large'),
        );
      }
    }

    if (await _networkInfo.isConnected) {
      try {
        final formData = FormData();
        formData.fields.add(MapEntry('orderIds', jsonEncode([oid])));
        for (final path in imagePaths) {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                path,
                filename: _fileName(path),
              ),
            ),
          );
        }
        final response = await _remoteDataSource.markOrdersPaid(formData);
        return _eitherFromResponse(response);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
