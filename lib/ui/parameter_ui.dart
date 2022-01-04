import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/common/app_switch.dart';
import 'package:flutter_builder/common/custom_drop_down.dart';
import 'package:flutter_builder/common/dialog_selection.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_creation/component_creation_cubit.dart';
import 'package:flutter_builder/cubit/parameter_build_cubit/parameter_build_cubit.dart';
import 'package:flutter_builder/models/other_model.dart';
import 'package:flutter_builder/models/parameter_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../enums.dart';

class ChoiceParameterWidget extends StatelessWidget {
  final ChoiceParameter parameter;

  const ChoiceParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null)
          Text(
            parameter.displayName!,
            style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        Expanded(
          child: BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState && (state2).parameter == parameter) return true;
              return false;
            },
            builder: (context, state) {
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
                                    Provider.of<ParameterBuildCubit>(context, listen: false)
                                        .parameterChanged(parameter);
                                    Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                                  }),
                              const SizedBox(
                                width: 5,
                              ),
                              if (subParam.displayName != null)
                                Flexible(
                                  child: Text(
                                    subParam.displayName!,
                                    style:
                                        const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (parameter.rawValue == subParam)
                          ParameterWidget(
                            parameter: subParam,
                          )
                      ],
                    )
                ],
              );
            },
          ),
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
    // final error = parameter?.checkIfValidToShow(
    //     Provider.of<ComponentSelectionCubit>(context, listen: false)
    //         .currentSelected);
    // if (error != null) {
    //   return Container(
    //     padding: const EdgeInsets.all(10),
    //     child: Text(
    //       'Please Note:$error',
    //       style: AppFontStyle.roboto(14, color: Colors.red.shade600),
    //     ),
    //   );
    // }
    if (parameter is SimpleParameter) {
      // logger('paramm ${param.name} ${param.runtimeType}');
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
        return ChoiceValueParameterWidget(parameter: parameter as ChoiceValueParameter);
      case ChoiceValueListParameter:
        return ChoiceValueListParameterWidget(parameter: parameter as ChoiceValueListParameter);
      case ListParameter:
        return ListParameterWidget(parameter: parameter as ListParameter);
      case BooleanParameter:
        return BooleanParameterWidget(parameter: parameter as BooleanParameter);
      default:
        return Container();
    }
  }
}

class SimpleParameterWidget extends StatelessWidget {
  final SimpleParameter parameter;

  const SimpleParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (parameter.displayName != null)
            Expanded(
              child: Text(
                parameter.displayName!,
                style: AppFontStyle.roboto(14, color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Container(
              height: 35,
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
          width: 70,
          child: TextField(
            // key:  parameter.name=='color'?GlobalObjectKey('simple ${parameter.name}'):null,
            controller: TextEditingController.fromValue(TextEditingValue(text: '${parameter.rawValue ?? ''}')),
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
              Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
            },
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                enabled: true,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5))),
          ),
        );
      case ParamInputType.longText:
        return SizedBox(
          width: 150,
          child: TextField(
            controller: TextEditingController.fromValue(TextEditingValue(text: '${parameter.rawValue ?? ''}')),
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
              Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
            },
            decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                enabled: true,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5))),
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
                Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
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
                  Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                  setStateForSlider(() {});
                }),
          );
        });
      case ParamInputType.image:
        return StatefulBuilder(builder: (context, setStateForImage) {
          return InkWell(
            onTap: () {
              ImagePicker()
                  .pickImage(
                source: ImageSource.gallery,
              )
                  .then((value) {
                if (value != null) {
                  value.readAsBytes().then((bytes) {
                    parameter.val = ImageData(bytes, value.name, value.path);
                    setStateForImage(() {});
                    Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                  });
                }
              });
            },
            child: parameter.value != null
                ? Image.memory(
                    (parameter.value as ImageData).bytes!,
                    width: 40,
                    fit: BoxFit.fitHeight,
                  )
                : const Icon(
                    Icons.image,
                    size: 30,
                    color: Colors.grey,
                  ),
          );
        });
    }
  }
}

class ListParameterWidget extends StatelessWidget {
  final ListParameter parameter;

  const ListParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
      buildWhen: (state1, state2) {
        if (state2 is ParameterChangeState && (state2).parameter == parameter) return true;
        return false;
      },
      builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                if (parameter.displayName != null)
                  Text(
                    parameter.displayName!,
                    style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: Colors.blue,
                    size: 24,
                  ),
                  onPressed: () {
                    parameter.params.add(parameter.parameterGenerator());
                    Provider.of<ParameterBuildCubit>(context, listen: false).parameterChanged(parameter);
                  },
                ),
              ],
            ),
            for (int i = 0; i < parameter.params.length; i++)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            Provider.of<ParameterBuildCubit>(context, listen: false).parameterChanged(parameter);
                          },
                        ),
                      )
                    ],
                  ),
                ),
              )
          ],
        );
      },
    );
  }
}

class ChoiceValueParameterWidget extends StatelessWidget {
  final ChoiceValueParameter parameter;

  const ChoiceValueParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null)
          Text(
            parameter.displayName!,
            style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
          buildWhen: (state1, state2) {
            if (state2 is ParameterChangeState && (state2).parameter == parameter) return true;
            return false;
          },
          builder: (context, state) {
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
                              style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (key) {
                    parameter.val = key;
                    Provider.of<ParameterBuildCubit>(context, listen: false).parameterChanged(parameter);
                    Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                  },
                ));
          },
        )
      ],
    );
  }
}

class ChoiceValueListParameterWidget extends StatelessWidget {
  final ChoiceValueListParameter parameter;

  const ChoiceValueListParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parameter.displayName != null) ...[
            Text(
              parameter.displayName!,
              style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
          BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState && (state2).parameter == parameter) return true;
              return false;
            },
            builder: (context, state) {
              return Card(
                child: InkWell(
                  onTap: () {
                    Get.generalDialog(
                      barrierDismissible: false,
                      barrierLabel: 'barrierLabel',
                      barrierColor: Colors.black45,
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context3, animation, secondary) {
                        return Material(
                          color: Colors.transparent,
                          child: DialogSelection(
                            title: '${parameter.displayName}',
                            data: parameter.options.map((e) => e.toString()).toList(),
                            onSelection: (data) {
                              parameter.val = parameter.options.indexOf(data);
                              Provider.of<ParameterBuildCubit>(context, listen: false).parameterChanged(parameter);
                              Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                            },
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 12),
                    child: Text(
                      parameter.value,
                      style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class ComplexParameterWidget extends StatelessWidget {
  final ComplexParameter parameter;

  const ComplexParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null) ...[
          const SizedBox(
            height: 10,
          ),
          Text(
            parameter.displayName!,
            style: AppFontStyle.roboto(14, color: AppColors.theme.shade700, fontWeight: FontWeight.w800),
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

  const BooleanParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      padding: const EdgeInsets.all(5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            parameter.displayName!,
            style: AppFontStyle.roboto(14, color: Colors.black, fontWeight: FontWeight.w500),
          ),
          BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState && (state2).parameter == parameter) return true;
              return false;
            },
            builder: (context, state) {
              return AppSwitch(
                  value: parameter.val,
                  onToggle: (value) {
                    parameter.val = value;
                    Provider.of<ParameterBuildCubit>(context, listen: false).parameterChanged(parameter);
                    Provider.of<ComponentCreationCubit>(context, listen: false).changedComponent();
                  });
            },
          )
        ],
      ),
    );
  }
}
