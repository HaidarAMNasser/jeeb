import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/bloc/list_areas_bloc.dart';

class AreaSearchWidget extends StatefulWidget {
  const AreaSearchWidget({super.key});

  @override
  State<AreaSearchWidget> createState() => _AreaSearchWidgetState();
}

class _AreaSearchWidgetState extends State<AreaSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _onSearchSubmitted(String query) {
    context.read<ListAreasBloc>().add(
      GetAreasEvent(search: query.isEmpty ? null : query),
    );
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<ListAreasBloc>().add(const GetAreasEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      filledColor: ColorManager.transparent,
      hintText: AppTranslation.searchAreasHint,
      controller: _searchController,
      onSubmitted: _onSearchSubmitted,
      prefixIcon: Icon(Icons.search, color: ColorManager.primary),
      textColor: ColorManager.titlesColor,
      hintColor: ColorManager.textSecondary,
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: ColorManager.descriptionColor),
              onPressed: _onClearSearch,
            )
          : null,
    );
  }
}
