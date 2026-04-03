import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_bloc.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_event.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_state.dart';
import 'package:jeeb_app/features/basket/confirmation_section/data/helpers/basket_confirmation_submit_hint.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_map_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_products_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_summary_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_user_fields_section.dart';

/// Main column + scroll + submit bar for [BasketConfirmationPage] (presentation only).
class BasketConfirmationPageBody extends StatelessWidget {
  const BasketConfirmationPageBody({
    super.key,
    required this.state,
    required this.nameController,
    required this.streetController,
    required this.addressDetailsController,
    required this.phoneController,
    required this.onChangeLocation,
  });

  final BasketConfirmationState state;
  final TextEditingController nameController;
  final TextEditingController streetController;
  final TextEditingController addressDetailsController;
  final TextEditingController phoneController;
  final Future<void> Function() onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final total = state.items.fold<int>(0, (sum, i) => sum + i.totalPrice);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(AppPadding.p16),
            children: [
              BasketConfirmationSummarySection(totalMinorUnits: total),
              SizedBox(height: AppHeight.s16),
              BasketConfirmationProductsSection(
                items: state.items,
                merchantName: state.merchantName,
              ),
              SizedBox(height: AppHeight.s12),
              BasketConfirmationMapSection(
                latitude: state.latitude,
                longitude: state.longitude,
                isResolvingAddress: state.isResolvingAddress,
                country: state.country,
                city: state.city,
                streetPreview: state.street.trim().isEmpty
                    ? null
                    : state.street.trim(),
                onUpdateLocation: onChangeLocation,
              ),
              SizedBox(height: AppHeight.s12),
              BasketConfirmationUserFieldsSection(
                nameController: nameController,
                streetController: streetController,
                addressDetailsController: addressDetailsController,
                phoneController: phoneController,
                onStreetChanged: (v) => context
                    .read<BasketConfirmationBloc>()
                    .add(BasketConfirmationStreetChanged(v)),
                onNameChanged: (v) => context
                    .read<BasketConfirmationBloc>()
                    .add(BasketConfirmationNameChanged(v)),
                onAddressDetailsChanged: (v) => context
                    .read<BasketConfirmationBloc>()
                    .add(BasketConfirmationAddressDetailsChanged(v)),
                onPhoneChanged: (v) => context
                    .read<BasketConfirmationBloc>()
                    .add(BasketConfirmationPhoneChanged(v)),
              ),
              SizedBox(height: AppHeight.s48),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppPadding.p16,
              AppPadding.p8,
              AppPadding.p16,
              AppPadding.p16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () {
                        if (state.canSubmitOrder) {
                          context.read<BasketConfirmationBloc>().add(
                                const BasketConfirmationSubmitRequested(),
                              );
                        } else {
                          showBasketConfirmationSubmitHintToast(
                            isResolvingAddress: state.isResolvingAddress,
                            name: state.name,
                            street: state.street,
                            addressDetails: state.addressDetails,
                            phone: state.phone,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: AppPadding.p14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                child: CustomText(
                  text: AppTranslation.confirmOrder,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.defaultWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
