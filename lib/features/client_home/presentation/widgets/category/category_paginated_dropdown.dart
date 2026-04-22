import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_paginated_dropdown.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/category/list_category/data/repositories/list_category_repository.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart';

class CategoryPaginatedDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final String title;
  final String hintText;

  const CategoryPaginatedDropdown({
    super.key,
    required this.onChanged,
    required this.title,
    required this.hintText,
    this.initialValue,
  });

  @override
  State<CategoryPaginatedDropdown> createState() =>
      _CategoryPaginatedDropdownState();
}

class _CategoryPaginatedDropdownState extends State<CategoryPaginatedDropdown> {
  final ListCategoryRepository _repository = sl<ListCategoryRepository>();
  List<CategoryEntity> _categories = [];
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _limit = 20;
  CategoryEntity? _selectedCategory;
  bool _isDisposed = false;
  int _loadVersion = 0;

  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant CategoryPaginatedDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _safeSetState(() {
        if (widget.initialValue == null) {
          _selectedCategory = null;
        } else {
          _selectedCategory = _categories.cast<CategoryEntity?>().firstWhere(
            (c) => c?.id == widget.initialValue,
            orElse: () => _selectedCategory,
          );
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    final requestVersion = ++_loadVersion;
    final result = await _repository.getCategories(page: 1, limit: _limit);
    if (!mounted || _isDisposed || requestVersion != _loadVersion) return;
    result.fold(
      (failure) => null, // Handle failure if needed
      (paginatedData) {
        if (!mounted || _isDisposed || requestVersion != _loadVersion) return;
        _safeSetState(() {
          _categories = paginatedData.categories;
          _hasMore = paginatedData.pagination?.hasNextPage ?? false;
          if (widget.initialValue != null) {
            try {
              _selectedCategory = _categories.firstWhere(
                (c) => c.id == widget.initialValue,
              );
            } catch (_) {
              _selectedCategory = null;
            }
          }
        });
      },
    );
  }

  Future<void> _onLoadMore() async {
    if (!_hasMore) return;
    final nextPage = _currentPage + 1;
    final requestVersion = ++_loadVersion;
    final result = await _repository.getCategories(
      page: nextPage,
      limit: _limit,
    );
    if (!mounted || _isDisposed || requestVersion != _loadVersion) return;
    result.fold((failure) => null, (paginatedData) {
      if (!mounted || _isDisposed || requestVersion != _loadVersion) return;
      _safeSetState(() {
        _categories = [..._categories, ...paginatedData.categories];
        _hasMore = paginatedData.pagination?.hasNextPage ?? false;
        _currentPage = nextPage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaginatedDropdown<CategoryEntity>(
      title: widget.title,
      hintText: widget.hintText,
      selectedItem: _selectedCategory,
      items: _categories,
      hasMoreData: _hasMore,
      onLoadMore: _onLoadMore,
      onChanged: (category) {
        _safeSetState(() {
          _selectedCategory = category;
        });
        widget.onChanged(category?.id);
      },
      displayText: (category) => category.name,
      itemBuilder: (context, category, isSelected) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p16,
            vertical: AppHeight.s12,
          ),
          color: isSelected
              ? ColorManager.primary.withOpacity(0.1)
              : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: CustomText(
                  text: category.name,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: isSelected
                        ? ColorManager.primary
                        : ColorManager.productNameColor,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check,
                  color: Colors.orange, // Orange tick
                  size: 20,
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadVersion++;
    super.dispose();
  }
}
