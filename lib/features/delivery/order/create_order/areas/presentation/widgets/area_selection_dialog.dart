import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/bloc/list_areas_bloc.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/widgets/area_search_widget.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/widgets/area_selection_list.dart';

class AreaSelectionDialog extends StatefulWidget {
  const AreaSelectionDialog({super.key});

  @override
  State<AreaSelectionDialog> createState() => _AreaSelectionDialogState();
}

class _AreaSelectionDialogState extends State<AreaSelectionDialog> {
  late final ListAreasBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<ListAreasBloc>()..add(const GetAreasEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _onAreaSelected(AreaEntity area) {
    Navigator.of(context).pop(area);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        child: Container(
          padding: EdgeInsets.all(AppPadding.p24),
          decoration: BoxDecoration(
            color: ColorManager.background,
            borderRadius: BorderRadius.circular(AppRadius.r20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                text: AppTranslation.selectArea,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: ColorManager.titlesColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppHeight.s16),
              const AreaSearchWidget(),
              SizedBox(height: AppHeight.s16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: AreaSelectionList(
                  bloc: _bloc,
                  onAreaSelected: _onAreaSelected,
                ),
              ),
              SizedBox(height: AppHeight.s24),
              CustomButton(
                text: AppTranslation.close,
                onPressed: () => Navigator.of(context).pop(),
                isOutlined: true,
                color: ColorManager.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
