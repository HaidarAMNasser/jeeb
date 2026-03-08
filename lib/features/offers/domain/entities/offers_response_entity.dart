import 'package:equatable/equatable.dart';
import 'offer_entity.dart';
import 'pagination_entity.dart';

class OffersResponseEntity extends Equatable {
  final String message;
  final List<OfferEntity> data;
  final PaginationEntity pagination;
  final DateTime timestamp;
  final String path;

  const OffersResponseEntity({
    required this.message,
    required this.data,
    required this.pagination,
    required this.timestamp,
    required this.path,
  });

  @override
  List<Object?> get props => [
        message,
        data,
        pagination,
        timestamp,
        path,
      ];
}
