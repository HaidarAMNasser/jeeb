import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class OrderHeaderCard extends StatelessWidget {
  final OrderEntity order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: '${AppTranslation.order} #${order.id}',
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.productNameColor,
              ),
            ),
            if (order.status != null) ...[
              SizedBox(height: AppHeight.s8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.p8,
                  vertical: AppPadding.p4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: CustomText(
                  text: order.status!,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: _getStatusColor(order.status!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return ColorManager.primary;
    }
  }
}

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
    context.read<ListOrderBloc>().add(const GetOrdersEvent());
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
        prefixIcon: Icon(Icons.search, color: ColorManager.primary),
        textColor: ColorManager.productNameColor,
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
