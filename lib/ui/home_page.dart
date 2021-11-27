import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/enums.dart';
import 'package:flutter_builder/screen_model.dart';
import 'package:flutter_builder/ui/component_selection.dart';
import 'package:flutter_builder/ui/parameter_ui.dart';

import '../component_list.dart';
import '../component_model.dart';
import 'component_tree.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScreenConfig screenConfig = screenConfigs[0];
  final componentPropertyCubit = ComponentPropertyCubit();
  final componentOperationCubit =
      ComponentOperationCubit(componentList['Container']!());
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
          ],
          child: Row(
            children: [
              Expanded(
                child: _buildLeftSide(),
              ),
              const SizedBox(
                width: 200,
                child: ComponentTree(),
              ),
              const SizedBox(
                width: 150,
                child: ComponentSelection(),
              ),
              SizedBox(
                width: 300,
                child: BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
                  builder: (context, state) {
                    return ListView(
                      children: [
                        for (final param
                        in componentSelectionCubit.currentSelected.parameters)
                          ParameterWidget(parameter: param,),
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
        child: Container(
          width: screenConfig.width,
          height: screenConfig.height,
          child: Align(
            alignment: Alignment.topLeft,
            child:
                BlocListener<ComponentPropertyCubit,ComponentPropertyState>(
                  listener: (context,state){
                    print(componentOperationCubit.rootComponent.code());
                  },
                  child: BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
              builder: (context, state) {

                  return componentOperationCubit.rootComponent.build(context);
              },
            ),
                ),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey, width: 2),
            color: Colors.white,
          ),
        ),
      ),
    );
  }


}
