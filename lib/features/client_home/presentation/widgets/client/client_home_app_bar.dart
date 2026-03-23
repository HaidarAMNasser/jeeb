import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';

/// App bar with profile avatar **before** the welcome / name text (same side).
class ClientHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClientHomeAppBar({super.key});

  static const double _toolbarHeight = 72;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorManager.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _toolbarHeight,
      titleSpacing: AppPadding.p16,
      automaticallyImplyLeading: false,
      title: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          String name = '';
          String? imageUrl;
          if (state is ProfileLoaded) {
            name = state.user.firstName;
            imageUrl = state.user.profileImageUrl;
          }
          final displayName = name.trim().isEmpty ? 'there' : name.trim();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => AppRouter.navigateTo(context, Routes.profile),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorManager.surface,
                    border: Border.all(
                      color: ColorManager.primary.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CustomCachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.person, color: ColorManager.primary),
                  ),
                ),
              ),
              SizedBox(width: AppWidth.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: 'Welcome back',
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppHeight.s2_5),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hello, ',
                            style: getSemiBoldStyle(
                              fontSize: AppFontSize.s20,
                              color: ColorManager.titlesColor.withOpacity(0.85),
                            ),
                          ),
                          TextSpan(
                            text: displayName,
                            style: getBoldStyle(
                              fontSize: AppFontSize.s20,
                              color: ColorManager.primary,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
