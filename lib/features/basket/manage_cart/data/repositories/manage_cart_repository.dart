import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/basket/manage_cart/data/data_sources/manage_cart_remote_data_source.dart';
import 'package:jeeb_app/features/basket/list_cart/data/mappers/basket_mapper.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_model.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_entity.dart';

class ManageCartRepository {
  final ManageCartRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ManageCartRepository(this._remote, this._networkInfo);

  BasketEntity? _parseCartFromSuccessResponse(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final code = raw['statusCode'] as int? ?? raw['status_code'] as int?;
    if ((code == 200 || code == 201) && raw['data'] is Map<String, dynamic>) {
      return BasketModel.fromJson(raw['data'] as Map<String, dynamic>).toDomain();
    }
    return null;
  }

  Future<bool> _hasExistingCart() async {
    try {
      final response = await _remote.getCart();
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final code = raw['statusCode'] as int? ?? raw['status_code'] as int?;
        if (code != 200) return false;
        final data = raw['data'];
        if (data == null) return false;
        if (data is Map<String, dynamic>) {
          // Some backends return 200 with empty object for "no cart".
          if (data.isEmpty) return false;
          return data['id'] != null;
        }
        return false;
      }
      return false;
    } on DioException catch (e) {
      // 404 means cart does not exist yet.
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<Either<Failure, BasketEntity>> addProduct({
    required String productId,
    int quantity = 1,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    final id = int.tryParse(productId);
    if (id == null) return const Left(ServerFailure(message: 'Invalid product id'));

    try {
      final hasCart = await _hasExistingCart();
      if (hasCart) {
        try {
          final patchResponse = await _remote.updateCart({
            'add': {
              'items': [
                {'productId': id, 'quantity': quantity},
              ],
            },
          });
          final parsed = _parseCartFromSuccessResponse(patchResponse.data);
          if (parsed != null) return Right(parsed);
        } on DioException catch (e) {
          // If cart vanished between GET and PATCH, fallback to create.
          if (e.response?.statusCode != 404) rethrow;
        }
      }

      final createResponse = await _remote.createCart({
        'items': [
          {'productId': id, 'quantity': quantity},
        ],
      });
      final parsedCreate = _parseCartFromSuccessResponse(createResponse.data);
      if (parsedCreate != null) return Right(parsedCreate);
      final raw = createResponse.data is Map<String, dynamic>
          ? createResponse.data as Map<String, dynamic>
          : null;
      return Left(
        ServerFailure(message: raw?['message']?.toString() ?? 'Failed to add to cart'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, BasketEntity>> addOffer({
    required String offerId,
    int quantity = 1,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    final id = int.tryParse(offerId);
    if (id == null) return const Left(ServerFailure(message: 'Invalid offer id'));

    try {
      final hasCart = await _hasExistingCart();
      if (hasCart) {
        try {
          final patchResponse = await _remote.updateCart({
            'add': {
              'offers': [
                {'offerId': id, 'quantity': quantity},
              ],
            },
          });
          final parsed = _parseCartFromSuccessResponse(patchResponse.data);
          if (parsed != null) return Right(parsed);
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) rethrow;
        }
      }

      final createResponse = await _remote.createCart({
        'offers': [
          {'offerId': id, 'quantity': quantity},
        ],
      });
      final parsedCreate = _parseCartFromSuccessResponse(createResponse.data);
      if (parsedCreate != null) return Right(parsedCreate);
      final raw = createResponse.data is Map<String, dynamic>
          ? createResponse.data as Map<String, dynamic>
          : null;
      return Left(
        ServerFailure(message: raw?['message']?.toString() ?? 'Failed to add offer to cart'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, BasketEntity>> updateItemQuantity({
    required String productId,
    required int quantity,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    final id = int.tryParse(productId);
    if (id == null) return const Left(ServerFailure(message: 'Invalid product id'));
    if (quantity < 1) return const Left(ServerFailure(message: 'Quantity must be at least 1'));
    try {
      final response = await _remote.updateCart({
        'update': {
          'items': [
            {'productId': id, 'quantity': quantity},
          ],
        },
      });
      final raw = response.data;
      if (raw is! Map<String, dynamic>) return const Left(ServerFailure(message: 'Invalid response'));
      final code = raw['statusCode'] as int? ?? raw['status_code'] as int?;
      if ((code == 200 || code == 201) && raw['data'] is Map<String, dynamic>) {
        return Right(BasketModel.fromJson(raw['data'] as Map<String, dynamic>).toDomain());
      }
      return Left(ServerFailure(message: raw['message']?.toString() ?? 'Failed to update cart'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, BasketEntity?>> removeItem(String productId) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    final id = int.tryParse(productId);
    if (id == null) return const Left(ServerFailure(message: 'Invalid product id'));
    try {
      final response = await _remote.updateCart({
        'remove': {
          'items': [id],
        },
      });
      final raw = response.data;
      if (raw is! Map<String, dynamic>) return const Left(ServerFailure(message: 'Invalid response'));
      final code = raw['statusCode'] as int? ?? raw['status_code'] as int?;
      if (code == 200) {
        if (raw['data'] == null) return const Right(null);
        if (raw['data'] is Map<String, dynamic>) {
          return Right(BasketModel.fromJson(raw['data'] as Map<String, dynamic>).toDomain());
        }
      }
      return Left(ServerFailure(message: raw['message']?.toString() ?? 'Failed to remove item'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, Unit>> clearCart() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await _remote.clearCart();
      final raw = response.data;
      if (raw is! Map<String, dynamic>) return const Left(ServerFailure(message: 'Invalid response'));
      final code = raw['statusCode'] as int? ?? raw['status_code'] as int?;
      if (code == 200) return const Right(unit);
      return Left(ServerFailure(message: raw['message']?.toString() ?? 'Failed to clear cart'));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        // Already empty/non-existing cart.
        return const Right(unit);
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, BasketEntity?>> replaceCartItems({
    required List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> offers = const [],
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      // Always clear then recreate from local draft.
      final clearResult = await clearCart();
      final clearFailed = clearResult.fold((f) => f, (_) => null);
      if (clearFailed != null) return Left(clearFailed);

      if (items.isEmpty && offers.isEmpty) {
        return const Right(null);
      }

      final response = await _remote.createCart({
        'items': items,
        'offers': offers,
      });
      final parsed = _parseCartFromSuccessResponse(response.data);
      if (parsed != null) return Right(parsed);

      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
      return Left(
        ServerFailure(
          message: raw?['message']?.toString() ?? 'Failed to save cart changes',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
