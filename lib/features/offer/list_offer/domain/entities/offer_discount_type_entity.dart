import 'package:equatable/equatable.dart';

/// Represents an offer discount type (e.g. Percentage, Fixed Value).
/// Used in create/edit offer form instead of fixed string types.
class OfferDiscountTypeEntity extends Equatable {
  final int id;
  final String title;

  const OfferDiscountTypeEntity({
    required this.id,
    required this.title,
  });

  /// API/code value sent to backend: PERCENTAGE | VALUE
  String get code {
    switch (id) {
      case 0:
        return 'PERCENTAGE';
      case 1:
        return 'VALUE';
      default:
        return 'PERCENTAGE';
    }
  }

  /// id 0 = Percentage, id 1 = Value (fixed value)
  static const List<OfferDiscountTypeEntity> values = [
    OfferDiscountTypeEntity(id: 0, title: 'Percentage'),
    OfferDiscountTypeEntity(id: 1, title: 'Value'),
  ];

  static OfferDiscountTypeEntity? fromCode(String code) {
    if (code == 'VALUE') return values[1];
    return values[0]; // PERCENTAGE or default
  }

  static OfferDiscountTypeEntity get percentage => values[0];
  static OfferDiscountTypeEntity get value => values[1];

  @override
  List<Object?> get props => [id, title];
}
