import 'package:equatable/equatable.dart';

class AreaEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int price;

  const AreaEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
  });

  /// Display price.
  int get displayPrice => price;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
      ];
}
