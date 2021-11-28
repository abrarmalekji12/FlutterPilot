import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_animated_dialog.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/screen_config/screen_config_cubit.dart';
import 'package:flutter_builder/enums.dart';
import 'package:flutter_builder/screen_model.dart';
import 'package:flutter_builder/ui/code_view_widget.dart';
import 'package:flutter_builder/ui/component_selection.dart';
import 'package:flutter_builder/ui/parameter_ui.dart';
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
  final componentPropertyCubit = ComponentPropertyCubit();
  final componentOperationCubit =
      ComponentOperationCubit(componentList['Scaffold']!());
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
            BlocProvider<ComponentPropertyCubit>(
                create: (context) => componentPropertyCubit),
            BlocProvider<ComponentOperationCubit>(
                create: (context) => componentOperationCubit),
            BlocProvider<ComponentSelectionCubit>(
                create: (context) => componentSelectionCubit),
            BlocProvider<ScreenConfigCubit>(
                create: (context) => screenConfigCubit),
          ],
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _buildLeftSide(),
                    const CodeViewerButton(),
                  ],
                ),
              ),
              const SizedBox(
                width: 200,
                child: ComponentTree(),
              ),
              const SizedBox(
                width: 200,
                child: ComponentSelection(),
              ),
              SizedBox(
                width: 300,
                child: BlocBuilder<ComponentSelectionCubit,
                    ComponentSelectionState>(
                  builder: (context, state) {
                    return ListView(
                      controller: propertyScrollController,
                      children: [
                        for (final param in componentSelectionCubit
                            .currentSelected.parameters)
                          ParameterWidget(
                            parameter: param,
                          ),
                      ],
                    );
                  },
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
      color: const Color(0xfff2f2f2),
      child: Center(
        child: BlocBuilder<ScreenConfigCubit, ScreenConfigState>(
          builder: (context, state) {
            return SizedBox(
              width: screenConfigCubit.screenConfig.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ScreenConfigSelection(),
                  Container(
                    width: screenConfigCubit.screenConfig.width,
                    height: screenConfigCubit.screenConfig.height,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: BlocListener<ComponentPropertyCubit,
                              ComponentPropertyState>(
                            listener: (context, state) {
                              print(
                                  componentOperationCubit.rootComponent.code());
                            },
                            child: BlocConsumer<ComponentOperationCubit,
                                ComponentOperationState>(
                              listener: (context, state) {
                                print(componentOperationCubit.rootComponent
                                    .code());
                              },
                              builder: (context, state) {
                                return componentOperationCubit.rootComponent
                                    .build(context);
                              },
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.5),
                            color: Colors.transparent,
                          ),
                        ),
                      ],
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
      child: CustomDropdownButton<ScreenConfig>(
          style: AppFontStyle.roboto(14),
          value: cubit.screenConfig,
          hint: null,
          items: cubit.screenConfigs
              .map<CustomDropdownMenuItem<ScreenConfig>>(
                (e) => CustomDropdownMenuItem<ScreenConfig>(
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
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            CustomDialog.show(
              context,
              CodeViewerWidget(
                code:
                    Provider.of<ComponentOperationCubit>(context, listen: false)
                        .rootComponent
                        .code(),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.blueAccent,
            child: Padding(
              padding: const EdgeInsets.all(10),
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
