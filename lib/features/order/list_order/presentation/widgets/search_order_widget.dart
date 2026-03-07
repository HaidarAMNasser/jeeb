import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';

class SearchOrderWidget extends StatefulWidget {
  const SearchOrderWidget({super.key});

  @override
  State<SearchOrderWidget> createState() => _SearchOrderWidgetState();
}

class _SearchOrderWidgetState extends State<SearchOrderWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _onSearchSubmitted(String query) {
    context.read<ListOrderBloc>().add(
          GetOrdersEvent(search: query.isEmpty ? null : query),
        );
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<ListOrderBloc>().add(
      const GetOrdersEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppPadding.p16),
      child: CustomTextField(
        hintText: AppTranslation.searchOrdersHint,
        controller: _searchController,
        onSubmitted: _onSearchSubmitted,
        prefixIcon: Icon(
          Icons.search,
          color: ColorManager.primary,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: ColorManager.descriptionColor,
                ),
                onPressed: _onClearSearch,
              )
            : null,
      ),
    );
  }
}

