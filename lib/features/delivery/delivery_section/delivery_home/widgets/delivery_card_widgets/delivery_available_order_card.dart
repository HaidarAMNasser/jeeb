import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

String _fmtMinor(int minor) =>
    '\$${(minor / 100).toStringAsFixed(2)}';

(int, int) _subtotalAndFeeMinor(OrderEntity o) {
  final fee = (o.deliveryFee ?? 0).round();
  if (o.totalPrice != null) {
    final total = o.totalPrice!.round();
    return (total - fee, fee);
  }
  final items = o.itemsTotal?.round() ??
      o.products.fold<int>(0, (s, p) => s + p.displayPrice);
  final offers = o.offersTotal?.round() ?? 0;
  return (items + offers, fee);
}

class DeliveryAvailableOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onAccept;
  final VoidCallback? onTap;
  final VoidCallback? onTimerExpired;

  const DeliveryAvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
    this.onTap,
    this.onTimerExpired,
  });

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);
    final showTimer = status == OrderStatus.searching;

    final restaurantName = order.owner?.restaurantName?.trim().isNotEmpty == true
        ? order.owner!.restaurantName!.trim()
        : (order.products.isNotEmpty
            ? order.products.first.merchantName ?? AppTranslation.restaurantName
            : AppTranslation.restaurantName);
    final restaurantAddr = order.owner?.address?.trim().isNotEmpty == true
        ? order.owner!.address!.trim()
        : (order.pickupAddress?.trim().isNotEmpty == true
            ? order.pickupAddress!.trim()
            : '');

    final clientName =
        order.displayCustomerName ?? AppTranslation.customer;
    final clientAddr = order.displayCustomerAddressLine ?? '';

    final (subMinor, feeMinor) = _subtotalAndFeeMinor(order);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p16,
        vertical: AppPadding.p8,
      ),
      child: Material(
        color: ColorManager.primaryDark,
        borderRadius: BorderRadius.circular(AppSize.s20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.s20),
          child: Container(
            padding: EdgeInsets.all(AppPadding.p16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.s20),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1 — Restaurant
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAvatarIcon(Icons.restaurant, Colors.orangeAccent),
                    SizedBox(width: AppWidth.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: restaurantName,
                            textStyle: getSemiBoldStyle(
                              fontSize: AppFontSize.s16,
                              color: ColorManager.primary,
                            ),
                          ),
                          if (restaurantAddr.isNotEmpty)
                            CustomText(
                              text: restaurantAddr,
                              textStyle: getRegularStyle(
                                fontSize: AppFontSize.s12,
                                color: ColorManager.textSecondary,
                              ),
                              maxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          text: AppTranslation.orderSubtotal,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s10,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                        CustomText(
                          text: _fmtMinor(subMinor),
                          textStyle: getBoldStyle(
                            fontSize: AppFontSize.s14,
                            color: ColorManager.titlesColor,
                          ),
                        ),
                        SizedBox(height: AppHeight.s4),
                        CustomText(
                          text: AppTranslation.deliveryPrice,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s10,
                            color: ColorManager.textSecondary,
                          ),
                        ),
                        CustomText(
                          text: _fmtMinor(feeMinor),
                          textStyle: getSemiBoldStyle(
                            fontSize: AppFontSize.s12,
                            color: ColorManager.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s16),
                // Row 2 — Client (no phone)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAvatarIcon(Icons.person, ColorManager.primary),
                    SizedBox(width: AppWidth.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: clientName,
                            textStyle: getBoldStyle(
                              fontSize: AppFontSize.s16,
                              color: ColorManager.titlesColor,
                            ),
                          ),
                          if (clientAddr.isNotEmpty)
                            CustomText(
                              text: clientAddr,
                              textStyle: getRegularStyle(
                                fontSize: AppFontSize.s12,
                                color: ColorManager.textSecondary,
                              ),
                              maxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: AppTranslation.acceptDelivery,
                        onPressed: onAccept,
                        height: AppHeight.s45,
                      ),
                    ),
                    SizedBox(width: AppWidth.s16),
                    if (showTimer)
                      _AcceptTimerCountdown(
                        key: ValueKey(
                          '${order.id}_${order.deliveryDeadline}_${order.remainingTime?.text?.text}_${order.remainingTime?.text?.minutes}_${order.remainingTime?.text?.seconds}',
                        ),
                        order: order,
                        onExpired: onTimerExpired,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcceptTimerCountdown extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback? onExpired;

  const _AcceptTimerCountdown({
    super.key,
    required this.order,
    this.onExpired,
  });

  @override
  State<_AcceptTimerCountdown> createState() => _AcceptTimerCountdownState();
}

class _AcceptTimerCountdownState extends State<_AcceptTimerCountdown> {
  Timer? _timer;
  int _secondsLeft = -1;
  bool _firedExpired = false;

  static const int _maxReasonableMinutes = 10080; // 7 days

  @override
  void initState() {
    super.initState();
    _secondsLeft = _computeInitialSeconds();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _AcceptTimerCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _computeInitialSeconds();
    if (next != _secondsLeft) {
      _timer?.cancel();
      setState(() {
        _secondsLeft = next;
        _firedExpired = false;
      });
      _startTicker();
    }
  }

  int _computeInitialSeconds() {
    final o = widget.order;
    if (o.deliveryDeadline != null) {
      final s = o.deliveryDeadline!.difference(DateTime.now()).inSeconds;
      return s > 0 ? s : 0;
    }
    final rt = o.remainingTime?.text;
    if (rt == null) return -1;
    final m = rt.minutes ?? 0;
    final sec = rt.seconds ?? 0;
    if (m > _maxReasonableMinutes) return -1;
    return m * 60 + sec;
  }

  void _startTicker() {
    if (_secondsLeft <= 0) {
      if (_secondsLeft == 0 && !_firedExpired) {
        _firedExpired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onExpired?.call();
        });
      }
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _timer = null;
        if (!_firedExpired) {
          _firedExpired = true;
          widget.onExpired?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatHms(int seconds) {
    if (seconds < 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.order.remainingTime?.displayLabel;

    return Container(
      constraints: BoxConstraints(maxWidth: AppWidth.s100),
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.s12),
      ),
      child: _secondsLeft > 0
          ? CustomText(
              text: _formatHms(_secondsLeft),
              textAlign: TextAlign.end,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s14,
                color: Colors.redAccent,
              ),
            )
          : (label != null && label.isNotEmpty
              ? CustomText(
                  text: label,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s10,
                    color: Colors.redAccent,
                  ),
                )
              : CustomText(
                  text: '—',
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: Colors.redAccent,
                  ),
                )),
    );
  }
}
