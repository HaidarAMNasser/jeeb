import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';

/// Search bar for products with filter button. Filter opens empty bottom sheet.
class ClientHomeSearchBar extends StatefulWidget {
  const ClientHomeSearchBar({super.key});

  @override
  State<ClientHomeSearchBar> createState() => _ClientHomeSearchBarState();
}

class _ClientHomeSearchBarState extends State<ClientHomeSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFilterTap() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorManager.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r16),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorManager.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppHeight.s24),
            // Empty for now - filter options later
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  void _onSearchSubmitted(String query) {
    context.read<ClientHomeCubit>().searchProducts(
      query.isEmpty ? null : query,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            hintText: AppTranslation.searchMerchantsHint,
            controller: _controller,
            onSubmitted: _onSearchSubmitted,
            prefixIcon: Icon(Icons.search, color: ColorManager.primary),
            filledColor: ColorManager.surface,
          ),
        ),
        SizedBox(width: AppPadding.p12),
        Material(
          color: ColorManager.primary,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: InkWell(
            onTap: _onFilterTap,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              child: Icon(
                Icons.filter_list,
                color: ColorManager.defaultWhite,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
