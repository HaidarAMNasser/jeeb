import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
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
  Timer? _debounce;
  Timer? _hintTimer;
  int _hintIndex = 0;

  List<String> _hintPhrases() {
    return [
      AppTranslation.searchHintRestaurants,
      AppTranslation.searchHintFavoriteFood,
      AppTranslation.searchHintOffers,
    ];
  }

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _hintIndex = (_hintIndex + 1) % _hintPhrases().length;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hintTimer?.cancel();
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
    if (query.isNotEmpty) {
      context.read<ClientHomeBloc>().add(GlobalSearchEvent(query));
    } else if (query.isEmpty) {
      context.read<ClientHomeBloc>().add(const RefreshClientHomeEvent());
    }
  }

  // void _onSearchChanged(String query) {
  //   setState(() {});
  //   _debounce?.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 350), () {
  //     if (!mounted) return;
  //     if (query.length >= 3) {
  //       context.read<ClientHomeBloc>().add(GlobalSearchEvent(query));
  //     } else if (query.isEmpty) {
  //       context.read<ClientHomeBloc>().add(const RefreshClientHomeEvent());
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final hints = _hintPhrases();
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppPadding.p8),
            child: CustomTextField(
              hintText: hints[_hintIndex % hints.length],
              controller: _controller,
              onChanged: (val) {},
              onSubmitted: _onSearchSubmitted,
              prefixIcon: Icon(Icons.search, color: ColorManager.primary),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      color: ColorManager.textSecondary,
                      onPressed: () {
                        _debounce?.cancel();
                        _controller.clear();
                        setState(() {});
                        context.read<ClientHomeBloc>().add(
                          const RefreshClientHomeEvent(),
                        );
                      },
                    )
                  : null,
              filledColor: ColorManager.surface,
              textColor: ColorManager.productNameColor,
              hintColor: ColorManager.textSecondary,
            ),
          ),
        ),
        SizedBox(width: AppPadding.p8),
        HomeActionButton(
          icon: Icons.refresh,
          backgroundColor: ColorManager.surface,
          iconColor: ColorManager.primary,
          onTap: () {
            _debounce?.cancel();
            _controller.clear();
            context.read<ClientHomeBloc>().add(const RefreshClientHomeEvent());
          },
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
