import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/basket/manage_cart/presentation/bloc/manage_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/checkout_location_pick.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_bloc.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_event.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_state.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/widgets/basket_confirmation_page_body.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

/// Controllers mirror bloc state; edits dispatch events. Field sync + navigation live in [BasketConfirmationBloc].
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindControllersFromState());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressDetailsController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _bindControllersFromState() {
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

  void _applyPendingFieldSync(BasketConfirmationState state) {
    switch (state.pendingFieldSync) {
      case BasketConfirmationFieldSync.none:
        break;
      case BasketConfirmationFieldSync.initialSync:
        _streetController.text = state.street;
        if (_nameController.text.isEmpty && state.name.isNotEmpty) {
          _nameController.text = state.name;
        }
        if (_phoneController.text.isEmpty && state.phone.isNotEmpty) {
          _phoneController.text = state.phone;
        }
      case BasketConfirmationFieldSync.streetOnly:
        _streetController.text = state.street;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (previous, current) =>
              current.pendingFieldSync != BasketConfirmationFieldSync.none,
          listener: (context, state) {
            _applyPendingFieldSync(state);
            context.read<BasketConfirmationBloc>().add(
                  const BasketConfirmationFieldSyncConsumed(),
                );
          },
        ),
        BlocListener<BasketConfirmationBloc, BasketConfirmationState>(
          listenWhen: (previous, current) =>
              previous.createdOrderId != current.createdOrderId &&
              current.createdOrderId != null,
          listener: (context, state) {
            context.read<ManageCartBloc>().add(const ClearCartEvent());
            context.read<BasketConfirmationBloc>().add(
                  const BasketConfirmationSuccessHandled(),
                );
          },
        ),
      ],
      child: BlocBuilder<BasketConfirmationBloc, BasketConfirmationState>(
        builder: (context, state) {
          return ModalProgressHUD(
            progressIndicator: const CustomCircleIndicator(),
            inAsyncCall: state.isSubmitting,
            child: Scaffold(
              backgroundColor: ColorManager.background,
              appBar: CustomAppBar(title: AppTranslation.createOrder),
              body: BasketConfirmationPageBody(
                state: state,
                nameController: _nameController,
                streetController: _streetController,
                addressDetailsController: _addressDetailsController,
                phoneController: _phoneController,
                onChangeLocation: _changeLocation,
              ),
            ),
          );
        },
      ),
    );
  }
}
