import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorManager.background,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ??
          (automaticallyImplyLeading
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: ColorManager.titlesColor,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                )
              : null),
      iconTheme: IconThemeData(
        color: ColorManager.titlesColor,
      ),
      title: CustomText(
        text: title,
        textStyle: getBoldStyle(
          fontSize: AppFontSize.s18,
          color: ColorManager.titlesColor,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

