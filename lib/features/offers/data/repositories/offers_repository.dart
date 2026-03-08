import 'package:dartz/dartz.dart';
import '../../../../core/common/errors/failure.dart';
import '../../domain/entities/offers_response_entity.dart';

abstract class OffersRepository {
  Future<Either<Failure, OffersResponseEntity>> getOffers({
    int page = 1,
    int limit = 10,
    String? search,
    bool? isActive,
    String? merchantId,
  });
}
