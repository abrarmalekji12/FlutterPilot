import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/common/app_switch.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
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
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: ParameterWidget(
                            parameter: subParam,
                          ),
                        )
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
      case ListParameter:
        return ListParameterWidget(parameter: parameter as ListParameter);
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
      height: 35,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (parameter.displayName != null)
              Expanded(
                child: Text(
                  parameter.displayName!,
                  style: AppFontStyle.roboto(14,
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
      ),
    );
  }

  Widget _buildInputType(BuildContext context) {
    switch (parameter.inputType) {
      case ParamInputType.text:
        return SizedBox(
          width: 70,
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
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(3),
                enabled: true,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Colors.blueAccent, width: 1.5))),
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
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(3),
                enabled: true,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Colors.blueAccent, width: 1.5))),
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

class ListParameterWidget extends StatelessWidget {
  final ListParameter parameter;

  const ListParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(builder: (context, setStateForParameter) {
      return Column(
        children: [
          Row(
            children: [
              if (parameter.displayName != null)
                Text(
                  parameter.displayName!,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.blue,
                  size: 24,
                ),
                onPressed: () {
                  parameter.params.add(parameter.parameterGenerator());
                  setStateForParameter(() {});
                },
              ),
            ],
          ),
          for (int i = 0; i < parameter.params.length; i++)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    ParameterWidget(
                      parameter: parameter.params[i],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          parameter.params.removeAt(i);
                          setStateForParameter(() {});
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
        ],
      );
    });
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
              ));
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
        if (parameter.displayName != null) ... [
          const SizedBox(height: 10,),
          Text(
            parameter.displayName!,
            style: AppFontStyle.roboto(14,color: AppColors.theme.shade700,fontWeight: FontWeight.w800),
          ),
        ],
        const SizedBox(
          height: 5,
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

class BooleanParameterWidget extends StatelessWidget {
  final BooleanParameter parameter;

  const BooleanParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          parameter.displayName!,
          style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
        ),
        StatefulBuilder(
          builder: (context,setStateSwitch) {
            return AppSwitch(value: parameter.val, onToggle: (value){
              parameter.val=value;
              setStateSwitch((){});
            });
          }
        )
      ],
    );
  }
}
