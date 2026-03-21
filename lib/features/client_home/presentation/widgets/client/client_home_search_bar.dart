import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/home_action_button.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/home_filter_bottom_sheet.dart';

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
    final clientHomeBloc = context.read<ClientHomeBloc>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: clientHomeBloc,
        child: const HomeFilterBottomSheet(),
      ),
    );
  }

  void _onSearchSubmitted(String query) {
    context.read<ClientHomeBloc>().add(
      SearchProductsEvent(query.isEmpty ? null : query),
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
        SizedBox(width: AppPadding.p8),
        HomeActionButton(
          icon: Icons.favorite_border,
          backgroundColor: ColorManager.surface,
          iconColor: ColorManager.primary,
          onTap: () => AppRouter.navigateTo(context, Routes.favorites),
        ),
        SizedBox(width: AppPadding.p12),
        HomeActionButton(
          icon: Icons.filter_list,
          backgroundColor: ColorManager.primary,
          iconColor: ColorManager.defaultWhite,
          onTap: _onFilterTap,
        ),
      ],
    );
  }
}
