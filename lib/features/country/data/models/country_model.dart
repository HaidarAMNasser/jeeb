import '../../domain/entities/country_entity.dart';

class CountryNameModel {
  final String ar;
  final String en;

  CountryNameModel({
    required this.ar,
    required this.en,
  });

  factory CountryNameModel.fromJson(Map<String, dynamic> json) {
    return CountryNameModel(
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

  CountryName toDomain() {
    return CountryName(ar: ar, en: en);
  }
}

class CountryModel {
  final int id;
  final CountryNameModel name;
  final String code;
  final String callingCode;
  final String currencyCode;
  final String currencySymbol;
  final String currencySmallestUnit;
  final int currencyFactor;
  final bool isActive;

  CountryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.callingCode,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencySmallestUnit,
    required this.currencyFactor,
    required this.isActive,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as int? ?? 0,
      name: CountryNameModel.fromJson(
        json['name'] as Map<String, dynamic>? ?? {},
      ),
      code: json['code'] as String? ?? '',
      callingCode: json['callingCode'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '',
      currencySmallestUnit: json['currencySmallestUnit'] as String? ?? '',
      currencyFactor: json['currencyFactor'] as int? ?? 1,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.toJson(),
      'code': code,
      'callingCode': callingCode,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'currencySmallestUnit': currencySmallestUnit,
      'currencyFactor': currencyFactor,
      'isActive': isActive,
    };
  }

  CountryEntity toDomain() {
    return CountryEntity(
      id: id,
      name: name.toDomain(),
      code: code,
      callingCode: callingCode,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencySmallestUnit: currencySmallestUnit,
      currencyFactor: currencyFactor,
      isActive: isActive,
    );
  }
}

