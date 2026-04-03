import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Shows [customToast] for why checkout cannot proceed: address still loading,
/// or the **first** missing required field (name → street → address details → phone)
/// with a dedicated “please enter …” line for that field.
void showBasketConfirmationSubmitHintToast({
  required bool isResolvingAddress,
  required String name,
  required String street,
  required String addressDetails,
  required String phone,
}) {
  if (isResolvingAddress) {
    customToast(msg: AppTranslation.basketConfirmWaitAddress);
    return;
  }
  if (name.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterFullName);
    return;
  }
  if (street.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterStreet);
    return;
  }
  if (addressDetails.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterAddressDetails);
    return;
  }
  if (phone.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterPhone);
    return;
  }
}
