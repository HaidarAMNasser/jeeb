import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:slide_countdown/slide_countdown.dart';

/// Shared countdown: **[SlideCountdownSeparated]** so hours / minutes / seconds
/// slide visibly each tick (package animation).
enum DeliveryOrderCountdownVariant { deadline, mealPrep }

class DeliveryOrderHmsSlideCountdown extends StatelessWidget {
  final Duration remaining;
  final VoidCallback? onDone;
  final DeliveryOrderCountdownVariant variant;

  /// Shown when [remaining] is already zero before the widget mounts.
  final Widget? replacementIfAlreadyElapsed;

  /// Shown when the slide countdown reaches zero (passed to [SlideCountdownSeparated.replacement]).
  final Widget? replacementWhenDone;

  /// Smaller text/padding (e.g. compact order cards).
  final bool dense;

  /// Override text size (useful for very tight layouts).
  final double? fontSize;

  /// Override icon size (useful for very tight layouts).
  final double? iconSizeOverride;

  const DeliveryOrderHmsSlideCountdown({
    super.key,
    required this.remaining,
    this.onDone,
    this.variant = DeliveryOrderCountdownVariant.deadline,
    this.replacementIfAlreadyElapsed,
    this.replacementWhenDone,
    this.dense = false,
    this.fontSize,
    this.iconSizeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isDeadline = variant == DeliveryOrderCountdownVariant.deadline;
    final fg = isDeadline ? const Color(0xFFFF4D6D) : ColorManager.primary;
    final accent = isDeadline
        ? const Color(0xFFFF8FA3)
        : const Color(0xFF6AE2FF);
    final fs = fontSize ?? (dense ? AppFontSize.s12 : AppFontSize.s15);
    final br = dense ? AppSize.s10 : AppSize.s14;
    final iconSize = iconSizeOverride ?? (dense ? AppSize.s14 : AppSize.s18);

    if (remaining.inSeconds <= 0) {
      return replacementIfAlreadyElapsed ??
          CustomText(
            text: '—',
            textStyle: getBoldStyle(fontSize: fs, color: fg),
          );
    }

    /// Inner “digit cell” — each segment slides inside its own rounded box.
    final cellDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.06),
        ],
      ),
      borderRadius: BorderRadius.circular(AppSize.s8),
      border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: dense ? 4 : 6,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(br),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDeadline
              ? const [Color(0xFF4A1520), Color(0xFF2D0A12)]
              : const [Color(0xFF0C3045), Color(0xFF061A26)],
        ),
        border: Border.all(
          color: accent.withOpacity(0.75),
          width: dense ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: fg.withOpacity(0.35),
            blurRadius: dense ? 10 : 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppPadding.p6 : AppPadding.p10,
        vertical: dense ? AppPadding.p4 : AppPadding.p8,
      ),
      child: SlideCountdownSeparated(
        duration: remaining,
        icon: Padding(
          padding: EdgeInsetsDirectional.only(
            end: dense ? AppPadding.p6 : AppPadding.p8,
          ),
          child: Icon(
            isDeadline
                ? Icons.timer_outlined
                : Icons.local_fire_department_rounded,
            size: iconSize,
            color: accent,
          ),
        ),
        showZeroValue: true,
        shouldShowDays: (_) => false,
        shouldShowHours: (_) => true,
        shouldShowMinutes: (_) => true,
        shouldShowSeconds: (_) => true,
        separator: ':',
        separatorType: SeparatorType.symbol,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 5 : 7,
          vertical: dense ? 4 : 6,
        ),
        separatorPadding: EdgeInsets.symmetric(horizontal: dense ? 5 : 7),
        decoration: cellDecoration,
        style: getBoldStyle(
          fontSize: fs,
          color: Colors.white,
        ).copyWith(letterSpacing: 0.5),
        separatorStyle: getBoldStyle(fontSize: fs + 1, color: accent),
        slideDirection: SlideDirection.up,
        slideAnimationDuration: const Duration(milliseconds: 500),
        slideAnimationCurve: Curves.easeOutBack,
        replacement: replacementWhenDone,
        onDone: onDone,
      ),
    );
  }
}
