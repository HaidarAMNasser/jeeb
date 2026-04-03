import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/data/data_sources/order_before_confirm_remote_data_source.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/data/models/order_before_confirm_preview_model.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';

class OrderBeforeConfirmRepository {
  OrderBeforeConfirmRepository(this._remote, this._networkInfo);

  final OrderBeforeConfirmRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  Future<Either<Failure, OrderBeforeConfirmPreview>> calculateDeliveryCost({
    required int merchantId,
    required double destinationLat,
    required double destinationLng,
    required List<Map<String, dynamic>> products,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final body = <String, dynamic>{
        'merchantId': merchantId,
        'destination': {
          'lat': destinationLat,
          'lng': destinationLng,
        },
      };
      if (products.isNotEmpty) {
        body['products'] = products;
      }

      final response = await _remote.calculateDeliveryCost(body);
      final statusCode = response.statusCode ?? 0;
      final raw = response.data;

      if (statusCode < 200 || statusCode >= 300) {
        return Left(
          _failureFromBody(raw, statusCode),
        );
      }

      final root = _coerceStringKeyedMap(raw);
      if (root == null) {
        return Left(
          ErrorHandler.handle(
            FormatException('Invalid calculate delivery cost response'),
          ),
        );
      }

      final successFlag = root['success'];
      final explicitFailure =
          successFlag == false || successFlag == 'false';

      final dataRaw = root['data'];
      final data = dataRaw is Map
          ? _coerceStringKeyedMap(dataRaw)
          : null;

      if (explicitFailure || data == null) {
        return Left(_failureFromBody(root, statusCode));
      }

      // 200 or 201: some backends omit `success` or use strings; accept if `data` parses.
      try {
        return Right(OrderBeforeConfirmPreviewModel.fromDataMap(data));
      } catch (e) {
        return Left(ErrorHandler.handle(e));
      }
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  Failure _failureFromBody(dynamic raw, int statusCode) {
    final map = _coerceStringKeyedMap(raw);
    if (map != null) {
      final msg = map['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) {
        return ServerFailure(message: msg, code: statusCode);
      }
    }
    return ServerFailure(
      message: 'Request failed.',
      code: statusCode,
    );
  }

  /// Dio/JSON often yields `Map<dynamic, dynamic>`; avoid strict `Map<String, dynamic>` checks.
  static Map<String, dynamic>? _coerceStringKeyedMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return value.map(
          (k, v) => MapEntry(k.toString(), v),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
