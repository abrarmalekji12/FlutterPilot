import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/data_type.dart';
import 'package:flutter_builder/screen_model.dart';
import 'package:flutter_builder/ui/component_selection.dart';

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
      ComponentOperationCubit((componentList['Row']!() as MultiHolder));
  /*
  * ..addChildren([
        componentList['Container']!(),
        componentList['Padding']!(),
      ])
  * */
  late final ComponentSelectionCubit componentSelectionCubit;

  @override
  void initState() {
    // TODO: implement initState
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
                child: _buildPropertySelection(),
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
                BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
              builder: (context, state) {
                return BlocBuilder<ComponentPropertyCubit,
                    ComponentPropertyState>(
                  builder: (context, state) {
                    return componentOperationCubit.rootComponent.create();
                  },
                );
              },
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

  Widget _buildPropertySelection() {
    return BlocBuilder<ComponentSelectionCubit, ComponentSelectionState>(
      builder: (context, state) {
        return ListView(
          children: [
            for (final param
                in componentSelectionCubit.currentSelected.parameters)
              _buildParameter(param),
          ],
        );
      },
    );
  }

  Widget _buildParameter(Parameter? param) {
    if (param == null) return Container();
    if (param is SimpleParameter<double> ||
        param is SimpleParameter<int> ||
        param is SimpleParameter<String>) {
      // print('paramm ${param.name} ${param.runtimeType}');
      return _buildSimpleParameter(param as SimpleParameter);
    }
    switch (param.runtimeType) {
      case ChoiceParameter:
        return _buildChoiceParameter(param as ChoiceParameter);
      case ComplexParameter:
        return _buildComplexParameter(param as ComplexParameter);
      case ChoiceValueParameter:
        return _buildChoiceValueParameter(param as ChoiceValueParameter);
      default:
        return Container();
    }
  }

  Widget _buildSimpleParameter(SimpleParameter parameter) {
    // print('Simple param ${parameter.name}');
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Text(
            parameter.name,
            style: AppFontStyle.roboto(13,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 50,
            child: TextField(
              controller: TextEditingController.fromValue(
                  TextEditingValue(text: '${parameter.rawValue}')),
              onChanged: (value) {
                if (parameter.paramType == ParamType.string) {
                  parameter.val = value;
                } else if (parameter.paramType == ParamType.double) {
                  parameter.val = double.tryParse(value);
                } else if (parameter.paramType == ParamType.int) {
                  parameter.val = int.tryParse(value);
                }
                componentPropertyCubit.changedProperty();
              },
              decoration: const InputDecoration(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChoiceParameter(ChoiceParameter param) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.name,
          style: const TextStyle(
              fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: StatefulBuilder(builder: (context, setStateForChoiceChange) {
            return Column(
              children: [
                for (final subParam in param.options)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<Parameter>(
                          value: param.rawValue,
                          groupValue: subParam,
                          onChanged: (value) {
                            param.val = subParam;
                            setStateForChoiceChange(() {});
                            componentPropertyCubit.changedProperty();
                          }),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: _buildParameter(subParam),
                      ),
                    ],
                  )
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildComplexParameter(ComplexParameter param) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.name,
          style: const TextStyle(
              fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Column(
            children: [
              for (final subParam in param.params) _buildParameter(subParam)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceValueParameter(ChoiceValueParameter param) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          param.name,
          style: const TextStyle(
              fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        StatefulBuilder(builder: (context, setStateForSelectionChange) {
          return SizedBox(
            height: 45,
            child: CustomDropdownButton<String>(
              value: param.rawValue,
              hint: Text(
                'select ${param.name}',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              selectedItemBuilder: (BuildContext, key) {
                return Text(
                  key,
                  style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                );
              },
              items: param.options.keys
                  .map(
                    (e) => CustomDropdownMenuItem<String>(
                      value: e,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e,
                          style: AppFontStyle.roboto(14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (key) {
                param.val = key;
                setStateForSelectionChange(() {});
                componentPropertyCubit.changedProperty();
              },
            ),
          );
        })
      ],
    );
  }
}
