import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

void registerValidationToast({
  String? firstName,
  String? lastName,
  String? email,
  String? phone,
  String? password,
}) {
  if (firstName == null || firstName.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterFirstName);
    return;
  }

  if (lastName == null || lastName.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterLastName);
    return;
  }

  if (email == null || email.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterEmail);
    return;
  }

  if (phone == null || phone.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterPhone);
    return;
  }

  if (password == null || password.trim().isEmpty) {
    customToast(msg: AppTranslation.pleaseEnterPassword);
    return;
  }

  if (password.trim().length < 6) {
    customToast(msg: AppTranslation.passwordMustBeAtLeast6Characters);
    return;
  }

}

bool isRegisterFormValid({
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String password,
}) {
  if (firstName.trim().isEmpty) return false;
  if (lastName.trim().isEmpty) return false;
  if (email.trim().isEmpty) return false;
  if (phone.trim().isEmpty) return false;
  if (password.trim().isEmpty || password.trim().length < 6) return false;

  return true;
}
