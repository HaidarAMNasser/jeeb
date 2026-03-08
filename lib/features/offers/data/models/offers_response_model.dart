import '../../domain/entities/offers_response_entity.dart';
import '../../domain/entities/pagination_entity.dart';
import 'offer_model.dart';

class OffersResponseModel {
  final String message;
  final List<OfferModel> data;
  final PaginationModel pagination;
  final DateTime timestamp;
  final String path;

  OffersResponseModel({
    required this.message,
    required this.data,
    required this.pagination,
    required this.timestamp,
    required this.path,
  });

  factory OffersResponseModel.fromJson(Map<String, dynamic> json) {
    return OffersResponseModel(
      message: json['message']?.toString() ?? '',
      data:
          (json['data'] as List?)
              ?.map((e) => OfferModel.fromJson(e))
              .toList() ??
          [],
      pagination: PaginationModel.fromJson(json['pagination'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      path: json['path']?.toString() ?? '',
    );
  }

  OffersResponseEntity toDomain() {
    return OffersResponseEntity(
      message: message,
      data: data.map((e) => e.toDomain()).toList(),
      pagination: pagination.toDomain(),
      timestamp: timestamp,
      path: path,
    );
  }
}

class PaginationModel {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginationModel({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  toDomain() {
    return PaginationEntity(
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }
}
