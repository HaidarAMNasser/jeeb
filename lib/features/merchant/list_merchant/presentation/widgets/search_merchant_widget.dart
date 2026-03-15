import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';

class SearchMerchantWidget extends StatefulWidget {
  const SearchMerchantWidget({super.key});

  @override
  State<SearchMerchantWidget> createState() => _SearchMerchantWidgetState();
}

class _SearchMerchantWidgetState extends State<SearchMerchantWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  void _onSearchSubmitted(String query) {
    context.read<ListMerchantBloc>().add(
          GetMerchantsEvent(search: query.isEmpty ? null : query),
        );
  }

  void _onClearSearch() {
    _searchController.clear();
    context.read<ListMerchantBloc>().add(const GetMerchantsEvent());
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
        hintText: AppTranslation.searchMerchantsHint,
        controller: _searchController,
        onSubmitted: _onSearchSubmitted,
        prefixIcon: Icon(Icons.search, color: ColorManager.primary),
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
