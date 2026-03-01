import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/animated_border_wrapper.dart';

/// A reusable paginated dropdown widget with scroll detection
/// 
/// Generic type T should be the entity/model type
/// displayText function extracts the display text from the item
/// onLoadMore is called when user scrolls near bottom (90% threshold)
class CustomPaginatedDropdown<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) displayText;
  final ValueChanged<T?> onChanged;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreData;
  final bool isError;
  final String? errorMessage;
  final bool isRequired;
  final double? maxHeight;
  final bool isReadOnly;

  const CustomPaginatedDropdown({
    super.key,
    required this.title,
    required this.hintText,
    required this.items,
    this.selectedItem,
    required this.displayText,
    required this.onChanged,
    this.onLoadMore,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreData = true,
    this.isError = false,
    this.errorMessage,
    this.isRequired = false,
    this.maxHeight,
    this.isReadOnly = false,
  });

  @override
  State<CustomPaginatedDropdown<T>> createState() =>
      _CustomPaginatedDropdownState<T>();
}

class _CustomPaginatedDropdownState<T>
    extends State<CustomPaginatedDropdown<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_scrollController.position.outOfRange &&
        widget.hasMoreData &&
        !widget.isLoadingMore) {
      widget.onLoadMore?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CustomText(
              text: widget.title,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.defaultWhite,
              ),
            ),
            if (widget.isRequired)
              CustomText(
                text: ' *',
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.warning,
                ),
              ),
          ],
        ),
        SizedBox(height: AppHeight.s8),
        if (widget.isLoading)
          // Show only animated border during initial load (no circle indicator)
          AnimatedBorderWrapper(
            isLoading: true,
            borderRadius: AppRadius.r18,
            borderWidth: 3.0,
            child: Container(
              height: AppHeight.s56,
              decoration: BoxDecoration(
                color: ColorManager.defaultWhite,
                borderRadius: BorderRadius.circular(AppRadius.r18),
              ),
            ),
          )
        else if (widget.isError)
          Container(
            height: AppHeight.s56,
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              border: Border.all(color: ColorManager.warning),
            ),
            child: Center(
              child: CustomText(
                text: widget.errorMessage ?? 'Error loading data',
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.warning,
                ),
              ),
            ),
          )
        else
          AnimatedBorderWrapper(
            isLoading: widget.isLoadingMore,
            borderRadius: AppRadius.r18,
            borderWidth: 3.0,
            child: GestureDetector(
              onTap: widget.isReadOnly
                  ? null
                  : () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
              child: Container(
                height: AppHeight.s56,
                padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                decoration: BoxDecoration(
                  color: ColorManager.defaultWhite,
                  borderRadius: _isExpanded
                      ? BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.r18),
                          topRight: Radius.circular(AppRadius.r18),
                        )
                      : BorderRadius.circular(AppRadius.r18),
                  border: Border.all(
                    color: widget.isError
                        ? ColorManager.warning
                        : ColorManager.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        text: widget.selectedItem != null
                            ? widget.displayText(widget.selectedItem as T)
                            : widget.hintText,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s14,
                          color: widget.selectedItem != null
                              ? ColorManager.productNameColor
                              : ColorManager.descriptionColor,
                        ),
                      ),
                    ),
                    if (!widget.isReadOnly)
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: ColorManager.descriptionColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (_isExpanded && !widget.isReadOnly && widget.items.isNotEmpty)
          Container(
            constraints: BoxConstraints(
              maxHeight: widget.maxHeight ?? 250,
            ),
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              border: Border(
                left: BorderSide(color: ColorManager.borderColor),
                right: BorderSide(color: ColorManager.borderColor),
                bottom: BorderSide(color: ColorManager.borderColor),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.r18),
                bottomRight: Radius.circular(AppRadius.r18),
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.items.length + (widget.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: widget.isLoadingMore
                          ? const CustomCircleIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final item = widget.items[index];
                final isSelected = widget.selectedItem == item;

                return InkWell(
                  onTap: () {
                    widget.onChanged(item);
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                  child: Container(
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
                            text: widget.displayText(item),
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: isSelected
                                  ? ColorManager.primary
                                  : ColorManager.productNameColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 20,
                            color: ColorManager.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

