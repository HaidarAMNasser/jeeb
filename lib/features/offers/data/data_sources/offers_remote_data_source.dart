import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class OffersRemoteDataSource {
  Future<Response> getOffers({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
    String? merchantId,
  });
}
