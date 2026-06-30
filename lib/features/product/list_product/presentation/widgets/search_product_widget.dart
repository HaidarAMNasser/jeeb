import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';

class SearchProductWidget extends StatefulWidget {
  final String? merchantId;

  const SearchProductWidget({super.key, this.merchantId});

  @override
  State<SearchProductWidget> createState() => _SearchProductWidgetState();
}

class _SearchProductWidgetState extends State<SearchProductWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  void _onSearchSubmitted(String query) {
    context.read<ListProductBloc>().add(
      GetProductsEvent(
        merchantId: widget.merchantId,
        search: query.isEmpty ? null : query,
      ),
    );
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<ListProductBloc>().add(
      GetProductsEvent(merchantId: widget.merchantId),
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
        filledColor: ColorManager.transparent,
        hintText: AppTranslation.searchHintFavoriteFood,
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
      ),
    );
  }
}
