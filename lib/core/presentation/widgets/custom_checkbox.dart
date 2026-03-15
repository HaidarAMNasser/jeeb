import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';


class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final Color? activeColor;
  final Color? checkColor;
  final Color? borderColor;

  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.activeColor,
    this.checkColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final checkbox = Transform.scale(
      scale: 1.2,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? ColorManager.primary,
        checkColor: checkColor ?? Colors.white,
        side: BorderSide(
          color: borderColor ?? ColorManager.primary,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r4),
        ),
      ),
    );

    if (label != null) {
      return InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppPadding.p8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              checkbox,
              Text(
                label!,
                style: TextStyle(
                  color: ColorManager.textColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return checkbox;
  }
}

