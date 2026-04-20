import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/auth/profile/presentation/widgets/profile_form.dart';
import 'package:jeeb_app/features/auth/profile/presentation/widgets/profile_header.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePageContent extends StatelessWidget {
  final UserEntity user;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool isMerchant;
  /// From settings API; shown for [UserRole.delivery] only.
  final String? supportPhone;
  final VoidCallback onUpdate;
  final VoidCallback onChangeLanguage;
  final VoidCallback onUpdateLocation;
  final ValueChanged<bool> onAccountStatusChanged;
  final bool isUpdateLoading;
  final VoidCallback? onPickImage;

  const ProfilePageContent({
    super.key,
    required this.user,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.addressController,
    required this.isMerchant,
    this.supportPhone,
    required this.onUpdate,
    required this.onChangeLanguage,
    required this.onUpdateLocation,
    required this.onAccountStatusChanged,
    required this.isUpdateLoading,
    this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final supportTrimmed = supportPhone?.trim() ?? '';
    final showSupportRow =
        user.role == UserRole.delivery && supportTrimmed.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(user: user, onPickImage: onPickImage),
          if (showSupportRow) ...[
            SizedBox(height: AppHeight.s24),
            _ProfileDeliverySupportPhoneRow(supportPhone: supportTrimmed),
          ],
          SizedBox(height: AppHeight.s32),
          ProfileForm(
            isMerchant: isMerchant,
            onUpdateLocation: onUpdateLocation,
            onAccountStatusChanged: onAccountStatusChanged,
            onChangeLanguage: onChangeLanguage,
            formKey: formKey,
            user: user,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            phoneController: phoneController,
            addressController: addressController,
            onUpdate: onUpdate,
            isLoading: isUpdateLoading,
          ),
          SizedBox(height: AppHeight.s24),
        ],
      ),
    );
  }
}

class _ProfileDeliverySupportPhoneRow extends StatelessWidget {
  const _ProfileDeliverySupportPhoneRow({required this.supportPhone});

  final String supportPhone;

  static String _telPath(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-.()]'), '');

  Future<void> _call(BuildContext context) async {
    final raw = supportPhone.trim();
    if (raw.isEmpty) return;
    final path = _telPath(raw);
    if (path.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: path);
    try {
      if (await canLaunchUrl(uri) && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = supportPhone.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _call(context),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppPadding.p14),
          decoration: BoxDecoration(
            color: ColorManager.primaryDark,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: ColorManager.defaultWhite.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.support_agent_outlined,
                size: 22,
                color: ColorManager.primary,
              ),
              SizedBox(width: AppPadding.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: AppTranslation.orderStatusSupportNumberLabel,
                      textStyle: getMediumStyle(
                        fontSize: AppFontSize.s11,
                        color: ColorManager.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppHeight.s4),
                    CustomText(
                      text: s,
                      textStyle: getSemiBoldStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.defaultWhite,
                      ),
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.phone_outlined,
                size: 22,
                color: ColorManager.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
