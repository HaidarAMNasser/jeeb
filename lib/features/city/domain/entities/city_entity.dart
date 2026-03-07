import 'package:equatable/equatable.dart';

class CityName extends Equatable {
  final String ar;
  final String en;

  const CityName({
    required this.ar,
    required this.en,
  });

  @override
  List<Object> get props => [ar, en];
}

class CityEntity extends Equatable {
  final int id;
  final CityName name;
  final int countryId;

  const CityEntity({
    required this.id,
    required this.name,
    required this.countryId,
  });

  @override
  List<Object> get props => [id, name, countryId];
}

