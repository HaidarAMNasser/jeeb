import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';

class DeliveryHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DeliveryHomeAppBar({super.key});

  @override
  Size get preferredSize => Size.fromHeight(AppHeight.s78);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ColorManager.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppHeight.s78,
      titleSpacing: AppPadding.p16,
      automaticallyImplyLeading: false,
      title: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          String name = '';
          String? imageUrl;
          bool isLoading = state is ProfileLoading || state is ProfileInitial;

          if (state is ProfileLoaded) {
            name = '${state.user.firstName} ${state.user.lastName}';
            imageUrl = state.user.profileImageUrl;
          }
          final displayName = name.trim().isEmpty
              ? AppTranslation.partner
              : name.trim();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => AppRouter.navigateTo(context, Routes.profile),
                child: Container(
                  width: AppWidth.s48,
                  height: AppWidth.s48,
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
                        : isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.person,
                            color: ColorManager.primary,
                            size: AppSize.s24,
                          ),
                  ),
                ),
              ),
              SizedBox(width: AppWidth.s12),
              Expanded(
                child: GestureDetector(
                  onTap: () => AppRouter.navigateTo(context, Routes.profile),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomText(
                        text: AppTranslation.deliveryDashboard,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppHeight.s4),
                      isLoading
                          ? Container(
                              width: 100.w,
                              height: 18.h,
                              decoration: BoxDecoration(
                                color: ColorManager.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${AppTranslation.hello}, ',
                                    style: getSemiBoldStyle(
                                      fontSize: AppFontSize.s18,
                                      color: ColorManager.titlesColor
                                          .withOpacity(0.85),
                                    ),
                                  ),
                                  TextSpan(
                                    text: displayName,
                                    style: getBoldStyle(
                                      fontSize: AppFontSize.s18,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
