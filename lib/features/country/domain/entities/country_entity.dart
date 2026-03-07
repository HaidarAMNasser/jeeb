import 'package:equatable/equatable.dart';

class CountryName extends Equatable {
  final String ar;
  final String en;

  const CountryName({
    required this.ar,
    required this.en,
  });

  @override
  List<Object> get props => [ar, en];
}

class CountryEntity extends Equatable {
  final int id;
  final CountryName name;
  final String code;
  final String callingCode;
  final String currencyCode;
  final String currencySymbol;
  final String currencySmallestUnit;
  final int currencyFactor;
  final bool isActive;

  const CountryEntity({
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

  @override
  List<Object> get props => [
        id,
        name,
        code,
        callingCode,
        currencyCode,
        currencySymbol,
        currencySmallestUnit,
        currencyFactor,
        isActive,
      ];
}

