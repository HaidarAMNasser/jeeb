import 'package:jeeb_app/features/get_settings/domain/entities/settings_entity.dart';

/// Maps API response data map to [SettingsEntity].
/// API returns data as map of key -> { id, key, value, description, isActive, ... }.
class GetSettingsMapper {
  const GetSettingsMapper._();

  static String _valueToString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  static num _valueToNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  static SettingsEntity fromJson(Map<String, dynamic>? data) {
    if (data == null) {
      return const SettingsEntity(
        supportPhone: '',
        whatsappNumber: '',
        defaultProductCommissionRate: 0,
      );
    }

    final supportPhoneObj = data['supportPhone'] as Map<String, dynamic>?;
    final whatsappObj = data['whatsappNumber'] as Map<String, dynamic>?;
    final commissionObj =
        data['defaultProductCommissionRate'] as Map<String, dynamic>?;

    return SettingsEntity(
      supportPhone: _valueToString(supportPhoneObj?['value']),
      whatsappNumber: _valueToString(whatsappObj?['value']),
      defaultProductCommissionRate: _valueToNum(commissionObj?['value']),
    );
  }
}
