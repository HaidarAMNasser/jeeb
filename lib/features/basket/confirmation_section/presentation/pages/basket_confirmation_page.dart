import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/checkout_location_pick.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_bloc.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_event.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_state.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_map_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_products_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_summary_section.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_user_fields_section.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

/// Confirmation UI only; logic lives in [BasketConfirmationBloc].
class BasketConfirmationPage extends StatefulWidget {
  const BasketConfirmationPage({super.key});

  @override
  State<BasketConfirmationPage> createState() => _BasketConfirmationPageState();
}

class _BasketConfirmationPageState extends State<BasketConfirmationPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressDetailsController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressDetailsController = TextEditingController();
    _phoneController = TextEditingController();
    _streetController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedControllersFromBloc());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressDetailsController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _seedControllersFromBloc() {
    if (!mounted) return;
    final s = context.read<BasketConfirmationBloc>().state;
    _nameController.text = s.name;
    _streetController.text = s.street;
    _addressDetailsController.text = s.addressDetails;
    _phoneController.text = s.phone;
  }

  Future<void> _changeLocation() async {
    final picked = await pickCheckoutLocation(context);
    if (picked == null || !mounted) return;
    context.read<BasketConfirmationBloc>().add(
          BasketConfirmationLocationPicked(
            latitude: picked.lat,
            longitude: picked.lng,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (p, c) =>
              c.orderIdSuccess != null && c.orderIdSuccess != p.orderIdSuccess,
          listener: (context, state) {
            final id = state.orderIdSuccess!;
            Navigator.of(context).pop();
            AppRouter.navigateTo(
              context,
              Routes.orderStatus,
              arguments: {
                'orderId': id,
                'initialStatus': 'PENDING',
              },
            );
          },
        ),
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (p, c) =>
              c.submitError != null && c.submitError != p.submitError,
          listener: (context, state) {
            final msg = state.submitError;
            if (msg == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            context.read<BasketConfirmationBloc>().add(
                  const BasketConfirmationSubmitErrorCleared(),
                );
          },
        ),
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (p, c) => p.locationVersion != c.locationVersion,
          listener: (_, state) {
            _streetController.text = state.street;
          },
        ),
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (p, c) =>
              (p.name.isEmpty && c.name.isNotEmpty) ||
              (p.phone.isEmpty && c.phone.isNotEmpty),
          listener: (_, state) {
            if (_nameController.text.isEmpty && state.name.isNotEmpty) {
              _nameController.text = state.name;
            }
            if (_phoneController.text.isEmpty && state.phone.isNotEmpty) {
              _phoneController.text = state.phone;
            }
          },
        ),
      ],
      child: BlocBuilder<BasketConfirmationBloc, BasketConfirmationState>(
        builder: (context, state) {
          final total = state.items.fold<int>(0, (sum, i) => sum + i.totalPrice);

          return ModalProgressHUD(
            progressIndicator: const CustomCircleIndicator(),
            inAsyncCall: state.isSubmitting,
            child: Scaffold(
              backgroundColor: ColorManager.background,
              appBar: CustomAppBar(title: AppTranslation.createOrder),
              body: Column(
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
                          streetPreview: _streetController.text.trim().isEmpty
                              ? null
                              : _streetController.text.trim(),
                          onUpdateLocation: _changeLocation,
                        ),
                        SizedBox(height: AppHeight.s12),
                        BasketConfirmationUserFieldsSection(
                          nameController: _nameController,
                          streetController: _streetController,
                          addressDetailsController: _addressDetailsController,
                          phoneController: _phoneController,
                          onStreetChanged: (v) {
                            context.read<BasketConfirmationBloc>().add(
                                  BasketConfirmationStreetChanged(v),
                                );
                            setState(() {});
                          },
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
                              : () => context.read<BasketConfirmationBloc>().add(
                                    const BasketConfirmationSubmitRequested(),
                                  ),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
