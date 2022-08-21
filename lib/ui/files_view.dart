import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/custom_popup_menu_button.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/project_model.dart';
import 'image_selection.dart';

class FilesView extends StatefulWidget {
  const FilesView({Key? key}) : super(key: key);

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  late final FlutterProject project;
  late ComponentOperationCubit componentOperationCubit;

  @override
  void initState() {
    super.initState();
    project = ComponentOperationCubit.currentProject!;
    componentOperationCubit = context.read<ComponentOperationCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: Responsive.isLargeScreen(context)
                  ? dw(context, 60)
                  : double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(),
                      ),
                      Center(
                        child: Text(
                          'Files',
                          style: AppFontStyle.roboto(16,
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Text(
                    'Images',
                    style: AppFontStyle.roboto(14,
                        color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ImageSelectionWidget(
                    selectionEnable: false,
                    componentOperationCubit: componentOperationCubit,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
