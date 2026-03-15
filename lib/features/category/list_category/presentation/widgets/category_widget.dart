import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_paginated_dropdown.dart';
import 'package:jeeb_app/features/category/list_category/presentation/bloc/list_category_bloc.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Reusable category dropdown that loads categories from the API
/// and uses the same animated loading pattern as [CountryCityWidget].
class CategoryWidget extends StatefulWidget {
  final Function(CategoryEntity?) onSelectCategory;
  final String? selectedCategoryId;
  final bool isRequired;
  final bool isReadOnly;

  const CategoryWidget({
    super.key,
    required this.onSelectCategory,
    this.selectedCategoryId,
    this.isRequired = false,
    this.isReadOnly = false,
  });

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  @override
  void initState() {
    super.initState();
    context.read<ListCategoryBloc>().add(const GetCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListCategoryBloc, ListCategoryState>(
      builder: (context, state) {
        List<CategoryEntity> categories = [];
        bool isLoading = false;
        bool isError = false;
        String? errorMessage;

        if (state is ListCategoryLoading) {
          isLoading = true;
        } else if (state is ListCategoryError) {
          isError = true;
          errorMessage = state.message;
        } else if (state is ListCategoryLoaded) {
          categories = state.categories;
        }

        CategoryEntity? selectedItem;
        if (widget.selectedCategoryId != null && categories.isNotEmpty) {
          try {
            selectedItem = categories.firstWhere(
              (c) => c.id == widget.selectedCategoryId,
            );
          } catch (_) {
            selectedItem = null;
          }
        }

        return CustomPaginatedDropdown<CategoryEntity>(
          title: AppTranslation.selectCategory,
          hintText: AppTranslation.selectCategory,
          items: categories,
          selectedItem: selectedItem,
          displayText: (category) => category.name,
          onChanged: widget.onSelectCategory,
          onLoadMore: null,
          isLoading: isLoading,
          isLoadingMore: false,
          hasMoreData: false,
          isError: isError,
          errorMessage: errorMessage,
          isRequired: widget.isRequired,
          isReadOnly: widget.isReadOnly,
        );
      },
    );
  }
}
