import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/custom_extension_tile.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/extension_util.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../injector.dart';
import '../widgets/button/app_close_button.dart';
import 'image_selection.dart';
import 'navigation/animated_dialog.dart';

class FilesView extends StatefulWidget {
  const FilesView({Key? key}) : super(key: key);

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  late OperationCubit componentOperationCubit;

  @override
  void initState() {
    super.initState();
    componentOperationCubit = context.read<OperationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width:
            Responsive.isDesktop(context) ? dw(context, 60) : double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        height: dh(context, 90),
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Files',
                  style: AppFontStyle.headerStyle(),
                ),
                AppCloseButton(
                  onTap:()=> AnimatedDialog.hide(context),
                ),
              ],
            ),
            20.hBox,
            CustomExpansionTile(
              initiallyExpanded: true,
              collapsedBackgroundColor: ColorAssets.shimmerColor,
              backgroundColor: ColorAssets.shimmerColor,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              title: Text(
                'Images',
                style: AppFontStyle.titleStyle(),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  color: theme.background1,
                  child: ImageSelectionWidget(
                    selectionEnable: false,
                    operationCubit: componentOperationCubit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
