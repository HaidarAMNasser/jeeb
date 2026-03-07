import '../../domain/entities/city_entity.dart';

class CityNameModel {
  final String ar;
  final String en;

  CityNameModel({
    required this.ar,
    required this.en,
  });

  factory CityNameModel.fromJson(Map<String, dynamic> json) {
    return CityNameModel(
      ar: json['ar'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ar': ar,
      'en': en,
    };
  }

  CityName toDomain() {
    return CityName(ar: ar, en: en);
  }
}

class CityModel {
  final int id;
  final CityNameModel name;
  final int countryId;

  CityModel({
    required this.id,
    required this.name,
    required this.countryId,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int? ?? 0,
      name: CityNameModel.fromJson(
        json['name'] as Map<String, dynamic>? ?? {},
      ),
      countryId: json['countryId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'countryId': countryId,
    };
  }

  CityEntity toDomain() {
    return CityEntity(
      id: id,
      name: name.toDomain(),
      countryId: countryId,
    );
  }
}

