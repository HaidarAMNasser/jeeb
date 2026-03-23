import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/widgets/confirmation_items_section.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/widgets/confirmation_location_card.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/widgets/confirmation_payment_notice_card.dart';

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
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.latitude,
        widget.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _country = p.country;
          _city = _resolveCity(p);
          _streetController.text = _resolveStreet(p) ?? '';
          _isResolvingAddress = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isResolvingAddress = false);
  }

  String? _resolveCity(Placemark p) {
    if ((p.locality ?? '').isNotEmpty) return p.locality;
    if ((p.subAdministrativeArea ?? '').isNotEmpty) {
      return p.subAdministrativeArea;
    }
    return p.administrativeArea;
  }

  String? _resolveStreet(Placemark p) {
    final candidates = <String?>[
      _joinStreetParts(p.thoroughfare, p.subThoroughfare),
      p.street,
      p.thoroughfare,
      p.subLocality,
      p.name,
    ];
    for (final candidate in candidates) {
      final sanitized = _sanitizeStreetCandidate(candidate);
      if (sanitized != null) return sanitized;
    }
    return null;
  }

  String? _joinStreetParts(String? thoroughfare, String? subThoroughfare) {
    final main = thoroughfare?.trim() ?? '';
    final sub = subThoroughfare?.trim() ?? '';
    if (main.isEmpty && sub.isEmpty) return null;
    if (main.isEmpty) return sub;
    if (sub.isEmpty) return main;
    return '$main $sub';
  }

  String? _sanitizeStreetCandidate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (_looksLikePlaceCode(value)) return null;
    return value;
  }

  bool _looksLikePlaceCode(String value) {
    final compact = value.replaceAll(RegExp(r'[\s\-_]'), '');
    // Reject short opaque map codes like "GQH" or "A1B2".
    return compact.length <= 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(compact);
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
          CustomTextField(
            title: AppTranslation.street,
            hintText: AppTranslation.street,
            controller: _streetController,
            onChanged: (_) => setState(() {}),
            filledColor: ColorManager.surface,
            textColor: ColorManager.productNameColor,
            hintColor: ColorManager.textSecondary,
          ),
          SizedBox(height: AppHeight.s12),
          CustomTextField(
            title: AppTranslation.addressDetails,
            hintText: AppTranslation.enterAddress,
            controller: _addressDetailsController,
            filledColor: ColorManager.surface,
            textColor: ColorManager.productNameColor,
            hintColor: ColorManager.textSecondary,
          ),
          SizedBox(height: AppHeight.s12),
          CustomTextField(
            title: AppTranslation.phone,
            hintText: AppTranslation.enterPhone,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            filledColor: ColorManager.surface,
            textColor: ColorManager.productNameColor,
            hintColor: ColorManager.textSecondary,
          ),
        ],
      ),
    );
  }
}
