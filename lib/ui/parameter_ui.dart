import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/common/custom_animated_dialog.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_creation_cubit.dart';
import 'package:provider/provider.dart';

import '../enums.dart';
import '../parameter_model.dart';

class ChoiceParameterWidget extends StatelessWidget {
  final ChoiceParameter parameter;

  const ChoiceParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null)
          Text(
            parameter.displayName!,
            style: const TextStyle(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        Expanded(
          child: StatefulBuilder(builder: (context, setStateForChoiceChange) {
            return Column(
              children: [
                for (final subParam in parameter.options)
                  Column(
                    children: [
                      SizedBox(
                        height: 30,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Radio<Parameter>(
                                value: parameter.rawValue,
                                groupValue: subParam,
                                onChanged: (value) {
                                  parameter.val = subParam;
                                  setStateForChoiceChange(() {});
                                  Provider.of<ComponentCreationCubit>(context,
                                          listen: false)
                                      .changedProperty(context);
                                }),
                            const SizedBox(
                              width: 5,
                            ),
                            if (subParam.displayName != null)
                              Text(
                                subParam.displayName!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                      if (parameter.rawValue == subParam)
                        ParameterWidget(
                          parameter: subParam,
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
}

class ParameterWidget extends StatelessWidget {
  final Parameter? parameter;

  const ParameterWidget({Key? key, this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (parameter == null) return Container();
    if (parameter.runtimeType.toString().startsWith('SimpleParameter')) {
      // print('paramm ${param.name} ${param.runtimeType}');
      return SimpleParameterWidget(parameter: parameter as SimpleParameter);
    }
    switch (parameter.runtimeType) {
      case ChoiceParameter:
        return ChoiceParameterWidget(
          parameter: parameter as ChoiceParameter,
        );
      case ComplexParameter:
        return ComplexParameterWidget(
          parameter: parameter as ComplexParameter,
        );
      case ChoiceValueParameter:
        return ChoiceValueParameterWidget(
            parameter: parameter as ChoiceValueParameter);
      default:
        return Container();
    }
  }
}

class SimpleParameterWidget extends StatelessWidget {
  final SimpleParameter parameter;

  const SimpleParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (parameter.displayName != null)
            Expanded(
              child: Text(
                parameter.displayName!,
                style: AppFontStyle.roboto(13,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildInputType(context),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputType(BuildContext context) {
    switch (parameter.inputType) {
      case ParamInputType.text:
        return SizedBox(
          width: 50,
          child: TextField(
            // key:  parameter.name=='color'?GlobalObjectKey('simple ${parameter.name}'):null,
            controller: TextEditingController.fromValue(
                TextEditingValue(text: '${parameter.rawValue ?? ''}')),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (parameter.paramType == ParamType.string) {
                  parameter.val = value;
                } else if (parameter.paramType == ParamType.double) {
                  parameter.val = double.tryParse(value);
                } else if (parameter.paramType == ParamType.int) {
                  parameter.val = int.tryParse(value);
                }
              } else {
                parameter.val = null;
              }
              Provider.of<ComponentCreationCubit>(context, listen: false)
                  .changedProperty(context);
            },
            decoration:
                const InputDecoration(contentPadding: EdgeInsets.all(5)),
          ),
        );
      case ParamInputType.longText:
        return SizedBox(
          width: 150,
          child: TextField(
            // key:  parameter.name=='color'?GlobalObjectKey('simple ${parameter.name}'):null,
            controller: TextEditingController.fromValue(
                TextEditingValue(text: '${parameter.rawValue ?? ''}')),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (parameter.paramType == ParamType.string) {
                  parameter.val = value;
                } else if (parameter.paramType == ParamType.double) {
                  parameter.val = double.tryParse(value);
                } else if (parameter.paramType == ParamType.int) {
                  parameter.val = int.tryParse(value);
                }
              } else {
                parameter.val = null;
              }
              Provider.of<ComponentCreationCubit>(context, listen: false)
                  .changedProperty(context);
            },
            decoration:
                const InputDecoration(contentPadding: EdgeInsets.all(5)),
          ),
        );
      case ParamInputType.color:
        // TODO: Handle this case.
        return StatefulBuilder(builder: (context, setStateForColor) {
          return SizedBox(
            width: 15,
            child: ColorButton(
              color: parameter.value ?? Colors.transparent,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: parameter.value ?? Colors.transparent,
                border: Border.all(color: Colors.black, width: 1),
              ),
              // colorPickerWidth: 300,
              //   pickerColor: Colors.blueAccent,
              onColorChanged: (color) {
                parameter.val = color;
                setStateForColor(() {});
                Provider.of<ComponentCreationCubit>(context, listen: false)
                    .changedProperty(context);
              },
            ),
          );
        });
      case ParamInputType.sliderZeroToOne:
        // TODO: Handle this case.
        return StatefulBuilder(builder: (context, setStateForSlider) {
          return SizedBox(
            width: 300,
            child: Slider.adaptive(
                value: parameter.rawValue ?? 0,
                onChanged: (i) {
                  parameter.val = i;
                  Provider.of<ComponentCreationCubit>(context, listen: false)
                      .changedProperty(context);
                  setStateForSlider(() {});
                }),
          );
        });
    }
    return Container();
  }
}

class ChoiceValueParameterWidget extends StatelessWidget {
  final ChoiceValueParameter parameter;

  const ChoiceValueParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null)
          Text(
            parameter.displayName!,
            style: const TextStyle(
                fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        StatefulBuilder(builder: (context, setStateForSelectionChange) {
          return SizedBox(
            height: 45,
            child: CustomDropdownButton<String>(
              value: parameter.rawValue,
              hint: Text(
                'select ${parameter.displayName ?? 'option'}',
                style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              ),
              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
              selectedItemBuilder: (_, key) {
                return Text(
                  key,
                  style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                );
              },
              items: parameter.options.keys
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
                parameter.val = key;
                setStateForSelectionChange(() {});
                Provider.of<ComponentCreationCubit>(context, listen: false)
                    .changedProperty(context);
              },
            ),
          );
        })
      ],
    );
  }
}

class ComplexParameterWidget extends StatelessWidget {
  final ComplexParameter parameter;

  const ComplexParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null)
          Text(
            parameter.displayName!,
            style: const TextStyle(
                fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        Column(
          children: [
            for (final subParam in parameter.params)
              ParameterWidget(
                parameter: subParam,
              )
          ],
        ),
      ],
    );
  }
}
