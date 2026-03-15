import 'package:equatable/equatable.dart';

/// Entity for the three admin-editable settings: support phone, WhatsApp number, commission rate.
class SettingsEntity extends Equatable {
  final String supportPhone;
  final String whatsappNumber;
  final num defaultProductCommissionRate;

  const SettingsEntity({
    required this.supportPhone,
    required this.whatsappNumber,
    required this.defaultProductCommissionRate,
  });

  @override
  List<Object?> get props => [supportPhone, whatsappNumber, defaultProductCommissionRate];
}
