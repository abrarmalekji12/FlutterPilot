import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_animated_dialog.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_creation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/parameter_build_cubit/parameter_build_cubit.dart';
import 'package:flutter_builder/cubit/screen_config/screen_config_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/enums.dart';
import 'package:flutter_builder/screen_model.dart';
import 'package:flutter_builder/ui/boundary_widget.dart';
import 'package:flutter_builder/ui/code_view_widget.dart';
import 'package:flutter_builder/ui/component_selection.dart';
import 'package:flutter_builder/ui/parameter_ui.dart';
import 'package:flutter_builder/ui/visual_model.dart';
import 'package:flutter_builder/ui/visual_painter.dart';
import 'package:provider/provider.dart';

import '../component_list.dart';
import '../component_model.dart';
import 'component_tree.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController propertyScrollController = ScrollController();
  final componentPropertyCubit = ComponentCreationCubit();
  final componentOperationCubit =
  ComponentOperationCubit(componentList['Scaffold']!());
  final ParameterBuildCubit _parameterBuildCubit=ParameterBuildCubit();
  final visualBoxCubit = VisualBoxCubit();
  final screenConfigCubit = ScreenConfigCubit();

  /*
  * ..addChildren([
        componentList['Container']!(),
        componentList['Padding']!(),
      ])
  * */
  late final ComponentSelectionCubit componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    componentSelectionCubit = ComponentSelectionCubit(
        currentSelected: componentOperationCubit.rootComponent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ComponentCreationCubit>(
                create: (context) => componentPropertyCubit),
            BlocProvider<ComponentOperationCubit>(
                create: (context) => componentOperationCubit),
            BlocProvider<ComponentSelectionCubit>(
                create: (context) => componentSelectionCubit),
            BlocProvider<ScreenConfigCubit>(
                create: (context) => screenConfigCubit),
            BlocProvider<VisualBoxCubit>(create: (context) => visualBoxCubit),
          ],
          child: Row(
            children: [
              const SizedBox(
                width: 250,
                child: ComponentTree(),
              ),
              Expanded(
                child: Stack(
                  children: [
                    _buildLeftSide(),
                    const CodeViewerButton(),
                  ],
                ),
              ),

              // const SizedBox(
              //   width: 200,
              //   child: ComponentSelection(),
              // ),
              SizedBox(
                width: 300,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: BlocBuilder<ComponentSelectionCubit,
                      ComponentSelectionState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20,),
                          Text(componentSelectionCubit
                              .currentSelected.name, style: AppFontStyle.roboto(
                              18, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 20,),
                          Expanded(
                            child: BlocProvider(
                              create: (context) => _parameterBuildCubit,
                              child: ListView(
                                controller: propertyScrollController,
                                children: [
                                  for (final param in componentSelectionCubit
                                      .currentSelected.parameters)
                                    ParameterWidget(
                                      parameter: param,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSide() {
    return Container(
      color: const Color(0xffd3d3d3),
      child: Center(
        child: BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
          builder: (context, state) {
            return SizedBox(
              // width: screenConfigCubit.screenConfig.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ScreenConfigSelection(),
                  Expanded(
                    child: Transform.scale(
                      scale: 0.8,
                      child: GestureDetector(
                        onTapDown: (event) {
                          print(
                              'tappp ${event.localPosition.dx} ${event.localPosition
                                  .dy}');
                          final tappedComp = componentOperationCubit.rootComponent
                              .searchTappedComponent(event.localPosition);
                          if (tappedComp != null) {
                            componentSelectionCubit.changeComponentSelection(
                                tappedComp);
                          }
                        },
                        child: Container(
                          key: const GlobalObjectKey('device window'),
                          width: screenConfigCubit.screenConfig.width,
                          height: screenConfigCubit.screenConfig.height,
                          color: Colors.white,
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(1.0),
                                child: BlocListener<ComponentCreationCubit,
                                    ComponentCreationState>(
                                  listener: (context, state) {
                                    // print(
                                    //     componentOperationCubit.rootComponent.code());
                                  },
                                  child: componentOperationCubit.rootComponent
                                      .build(context),
                                ),
                              ),
                              const BoundaryWidget(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ScreenConfigSelection extends StatelessWidget {
  const ScreenConfigSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = Provider.of<ScreenConfigCubit>(context, listen: false);
    return SizedBox(
      width: 200,
      height: 50,
      child: CustomDropdownButton<ScreenConfig>(
          style: AppFontStyle.roboto(14),
          value: cubit.screenConfig,
          hint: null,
          items: cubit.screenConfigs
              .map<CustomDropdownMenuItem<ScreenConfig>>(
                (e) =>
                CustomDropdownMenuItem<ScreenConfig>(
                  value: e,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${e.name} (${e.width}x${e.height})',
                      style:
                      AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
          )
              .toList(),
          onChanged: (value) {
            cubit.changeScreenConfig(value);
          },
          selectedItemBuilder: (context, config) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${config.name} (${config.width}x${config.height})',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
            );
          }),
    );
  }
}

class CodeViewerButton extends StatelessWidget {
  const CodeViewerButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: InkWell(
          highlightColor: Colors.blueAccent.shade200,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            CustomDialog.show(
              context,
              CodeViewerWidget(
                code:
                Provider
                    .of<ComponentOperationCubit>(context, listen: false)
                    .rootComponent
                    .code(),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.code,
                    color: Colors.white,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'view code',
                    style: AppFontStyle.roboto(16, color: Colors.white),
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
