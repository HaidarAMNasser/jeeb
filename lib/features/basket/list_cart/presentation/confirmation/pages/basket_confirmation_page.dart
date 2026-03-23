import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/basket/list_cart/data/helpful_functions/address_resolver.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/widgets/confirmation_contact_fields_section.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/widgets/confirmation_items_section.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/widgets/confirmation_location_card.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/widgets/confirmation_payment_notice_card.dart';

class BasketConfirmationPage extends StatefulWidget {
  final List<ConfirmationItem> items;
  final String merchantName;
  final double latitude;
  final double longitude;
  final String initialPhone;

  const BasketConfirmationPage({
    super.key,
    required this.items,
    required this.merchantName,
    required this.latitude,
    required this.longitude,
    this.initialPhone = '',
  });

  @override
  State<BasketConfirmationPage> createState() => _BasketConfirmationPageState();
}

class _BasketConfirmationPageState extends State<BasketConfirmationPage> {
  late final TextEditingController _addressDetailsController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  String? _country;
  String? _city;
  bool _isResolvingAddress = true;

  @override
  void initState() {
    super.initState();
    _addressDetailsController = TextEditingController();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _streetController = TextEditingController();
    _resolveAddress();
  }

  @override
  void dispose() {
    _addressDetailsController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _resolveAddress() async {
    final resolved = await resolveAddressFromCoordinates(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
    if (!mounted) return;
    setState(() {
      _country = resolved?.country;
      _city = resolved?.city;
      _streetController.text = resolved?.street ?? '';
      _isResolvingAddress = false;
    });
  }

  String _price(int value) => (value / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.createOrder),
      body: ListView(
        padding: EdgeInsets.all(AppPadding.p16),
        children: [
          ConfirmationPaymentNoticeCard(
            totalText: '${AppTranslation.total}: \$${_price(total)}',
          ),
          SizedBox(height: AppHeight.s16),
          ConfirmationItemsSection(
            items: widget.items,
            merchantName: widget.merchantName,
          ),
          SizedBox(height: AppHeight.s8),
          ConfirmationLocationCard(
            latitude: widget.latitude,
            longitude: widget.longitude,
            isResolvingAddress: _isResolvingAddress,
            country: _country,
            city: _city,
            street: _streetController.text.trim().isEmpty
                ? null
                : _streetController.text.trim(),
          ),
          SizedBox(height: AppHeight.s12),
          ConfirmationContactFieldsSection(
            streetController: _streetController,
            addressDetailsController: _addressDetailsController,
            phoneController: _phoneController,
            onStreetChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
