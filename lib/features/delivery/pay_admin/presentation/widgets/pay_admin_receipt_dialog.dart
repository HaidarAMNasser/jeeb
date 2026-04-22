import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/pay_admin/domain/mediator_admin_fee.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/bloc/pay_admin_bloc.dart';

/// Receipt upload + admin fee total; submits via [PayAdminBloc].
class PayAdminReceiptDialog extends StatefulWidget {
  const PayAdminReceiptDialog({
    super.key,
    required this.orderIds,
    required this.ordersForTotals,
    this.onSuccess,
  });

  final List<String> orderIds;
  final List<OrderEntity> ordersForTotals;
  final VoidCallback? onSuccess;

  @override
  State<PayAdminReceiptDialog> createState() => _PayAdminReceiptDialogState();
}

class _PayAdminReceiptDialogState extends State<PayAdminReceiptDialog> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  double get _totalFee {
    final map = {for (final o in widget.ordersForTotals) o.id: o};
    final list = widget.orderIds.map((id) => map[id]).whereType<OrderEntity>();
    return sumMediatorAdminFees(list);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayAdminBloc, PayAdminState>(
      listener: (context, state) {
        if (state is PayAdminSuccess) {
          final bloc = context.read<PayAdminBloc>();
          customToast(msg: AppTranslation.payAdminSuccess);
          widget.onSuccess?.call();
          bloc.add(const PayAdminReset());
          Navigator.of(context).pop();
        } else if (state is PayAdminFailureState) {
          customToast(
            msg: '${AppTranslation.payAdminFailure}: ${state.message}',
            backgroundColor: Colors.red.shade700,
            textColor: Colors.white,
          );
        }
      },
      builder: (context, state) {
        final busy = state is PayAdminSubmitting;
        return Stack(
          children: [
            AlertDialog(
              backgroundColor: ColorManager.primaryDark,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                side: BorderSide(
                  color: ColorManager.defaultWhite.withValues(alpha: 0.12),
                ),
              ),
              title: CustomText(
                text: AppTranslation.payAdminMenuTitle,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.titlesColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomText(
                      text: AppTranslation.payAdminDialogInstructions,
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s13,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppHeight.s12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorManager.defaultWhite,
                        side: BorderSide(
                          color: ColorManager.primary.withValues(alpha: 0.75),
                        ),
                        backgroundColor: ColorManager.background,
                        surfaceTintColor: Colors.transparent,
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              final x = await _picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (!mounted || x == null) return;
                              setState(() => _imagePath = x.path);
                            },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(AppTranslation.payAdminPickReceipt),
                    ),
                    if (_imagePath != null) ...[
                      SizedBox(height: AppHeight.s8),
                      CustomText(
                        text: _imagePath!.split(RegExp(r'[\\/]')).last,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s11,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: AppHeight.s16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: AppTranslation.payAdminTotalLabel,
                          textStyle: getMediumStyle(
                            fontSize: AppFontSize.s14,
                            color: ColorManager.titlesColor,
                          ),
                        ),
                        CustomText(
                          text: _totalFee.toStringAsFixed(2),
                          textStyle: getBoldStyle(
                            fontSize: AppFontSize.s16,
                            color: ColorManager.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: ColorManager.textSecondary,
                  ),
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: Text(AppTranslation.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: ColorManager.defaultWhite,
                    surfaceTintColor: Colors.transparent,
                    disabledBackgroundColor:
                        ColorManager.primary.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        ColorManager.defaultWhite.withValues(alpha: 0.5),
                  ),
                  onPressed: busy || _imagePath == null
                      ? null
                      : () {
                          final path = _imagePath;
                          if (path == null) return;
                          context.read<PayAdminBloc>().add(
                                PayAdminSubmit(
                                  orderIds: widget.orderIds,
                                  receiptImagePath: path,
                                ),
                              );
                        },
                  child: Text(AppTranslation.payAdminSubmit),
                ),
              ],
            ),
            if (busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
