import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/custom_text_field.dart';
import '../common/dynamic_value_editing_controller.dart';
import '../common/dynamic_value_filed.dart';
import 'image_selection.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../common/app_switch.dart';
import '../common/custom_drop_down.dart';
import '../common/dialog_selection.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../models/other_model.dart';
import '../models/parameter_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../enums.dart';

class ChoiceParameterWidget extends StatelessWidget {
  final ChoiceParameter parameter;

  const ChoiceParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null) ...[
          SizedBox(
            width: 70,
            child: Text(
              parameter.displayName!,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            width: 3,
          ),
        ],
        Expanded(
          child: BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState &&
                  state2.parameter == parameter) {
                return true;
              }
              return false;
            },
            builder: (context, state) {
              return Column(
                children: [
                  for (final subParam in parameter.options)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: parameter.rawValue == subParam
                            ? BoxDecoration(
                                color: const Color(0xffedeff1),
                                borderRadius: BorderRadius.circular(10))
                            : null,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 23,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Radio<Parameter>(
                                      value: parameter.rawValue,
                                      groupValue: subParam,
                                      onChanged: (value) {
                                        parameter.val = subParam;
                                        Provider.of<ParameterBuildCubit>(
                                                context,
                                                listen: false)
                                            .parameterChanged(
                                                context, parameter);
                                        Provider.of<ComponentCreationCubit>(
                                                context,
                                                listen: false)
                                            .changedComponent();
                                      }),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  if (subParam.displayName != null)
                                    Flexible(
                                      child: Text(
                                        subParam.displayName!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
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
                        ),
                      ),
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
      return SimpleParameterWidget(parameter: parameter as SimpleParameter);
    } else if (parameter is ChoiceValueListParameter) {
      return ChoiceValueListParameterWidget(
          parameter: parameter as ChoiceValueListParameter);
    } else if (parameter is ListParameter) {
      return ListParameterWidget(parameter: parameter as ListParameter);
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
      case BooleanParameter:
        return BooleanParameterWidget(parameter: parameter as BooleanParameter);
      default:
        return Container();
    }
  }
}

class SimpleParameterWidget extends StatelessWidget {
  final SimpleParameter parameter;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DynamicValueEditingController _textEditingController =
      DynamicValueEditingController();

  SimpleParameterWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: const Color(0xfff2f2f2),
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(3),
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
            child: Container(
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
      case ParamInputType.longText:
      case ParamInputType.text:
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _textEditingController.text = parameter.compiler.code.isNotEmpty
              ? parameter.compiler.code
              : '${parameter.getValue() ?? ''}';
        });
        return Form(
          key: _formKey,
          child: SizedBox(
            width: parameter.inputType == ParamInputType.text ? 110 : 200,
            height: parameter.inputType != ParamInputType.text ? 60 : null,
            child: TextFormField(
              maxLines: parameter.inputType == ParamInputType.text ? null : 3,
              validator: (value) {
                final result = parameter.process(value ?? '');
                debugPrint('RESULT IS $value $result');
                if (result != null) {
                  parameter.compiler.code = value ?? '';
                  parameter.val = result;
                  if (parameter.inputCalculateAs != null) {
                    parameter.val =
                        parameter.inputCalculateAs!.call(parameter.val!, true);
                  }
                  BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                      .parameterChanged(context, parameter);
                  BlocProvider.of<ComponentCreationCubit>(context,
                          listen: false)
                      .changedComponent();
                  return null;
                }
                return '';
              },
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                return Text(
                  '${parameter.val}',
                  style: AppFontStyle.roboto(13,
                      fontWeight: FontWeight.w500, color: Colors.blueAccent),
                );
              },
              style: AppFontStyle.roboto(13, fontWeight: FontWeight.w600),
              controller: _textEditingController,
              onChanged: (value) {
                if (value.isNotEmpty || parameter.val is String) {
                  _formKey.currentState!.validate();
                  return;
                } else {
                  parameter.compiler.code = '';
                  parameter.val = null;
                }
                BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                    .parameterChanged(context, parameter);
                BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                    .changedComponent();
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical:
                          parameter.inputType == ParamInputType.text ? 0 : 5),
                  enabled: true,
                  errorText: null,
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
          ),
        );
      case ParamInputType.color:
        return ColorInputWidget(parameter: parameter);
      case ParamInputType.sliderZeroToOne:
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _textEditingController.text = parameter.compiler.code.isNotEmpty
              ? parameter.compiler.code
              : '${parameter.getValue() ?? ''}';
        });
        return DynamicValueField<double>(
            inputOption: InputOption.doubleZeroToOne,
            onProcessedResult: (code, result) {
              parameter.val = result;
              BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                  .parameterChanged(context, parameter);
              BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                  .changedComponent();
              return true;
            },
            onErrorCode: () {
              parameter.val = null;
              BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                  .parameterChanged(context, parameter);
              BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                  .changedComponent();
            },
            textEditingController: _textEditingController);
      case ParamInputType.image:
        return BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            builder: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            if (parameter.compiler.code.isNotEmpty) {
              _textEditingController.text = parameter.compiler.code;
            } else {
              _textEditingController.text =
                  (parameter.val as ImageData?)?.imageName ?? '';
            }
          });
          return StatefulBuilder(builder: (context, setStateForImage) {
            return InkWell(
              onTap: () {
                Get.dialog(
                  ImageSelectionWidget(
                      componentOperationCubit:
                          BlocProvider.of<ComponentOperationCubit>(context,
                              listen: false)),
                ).then((value) {
                  if (value != null && value is ImageData) {
                    parameter.val = value;
                    parameter.compiler.code = value.imageName!;
                    setStateForImage(() {});
                    BlocProvider.of<ComponentCreationCubit>(context,
                            listen: false)
                        .changedComponent();
                  }
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  parameter.value != null &&
                          ((parameter.value as ImageData).bytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            (parameter.value as ImageData).bytes!,
                            width: 40,
                            fit: BoxFit.fitHeight,
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 30,
                          color: Colors.grey,
                        ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 100,
                    child: DynamicValueField<String>(
                        onProcessedResult: (code, result) {
                          if (BlocProvider.of<ComponentOperationCubit>(context,
                                  listen: false)
                              .byteCache
                              .containsKey(result)) {
                            parameter.compiler.code = code;
                            (parameter.val as ImageData).imageName = result;
                            (parameter.val as ImageData).bytes =
                                BlocProvider.of<ComponentOperationCubit>(
                                        context,
                                        listen: false)
                                    .byteCache[result];

                            setStateForImage(() {});
                            BlocProvider.of<ComponentCreationCubit>(context,
                                    listen: false)
                                .changedComponent();
                            return true;
                          }
                          return false;
                        },
                        textEditingController: _textEditingController),
                  )
                ],
              ),
            );
          });
        });
    }
  }
}

Color? fromHex(String hexString) {
  if (hexString.length < 7) {
    return null;
  }
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final colorInt = int.tryParse(buffer.toString(), radix: 16);
  if (colorInt == null) {
    return null;
  }
  return Color(colorInt);
}

class ListParameterWidget extends StatelessWidget {
  final ListParameter parameter;

  const ListParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
      buildWhen: (state1, state2) {
        if (state2 is ParameterChangeState && state2.parameter == parameter) {
          return true;
        }
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
                    BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                        .parameterChanged(context, parameter);
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ParameterWidget(
                          parameter: parameter.params[i],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          parameter.params.removeAt(i);
                          BlocProvider.of<ParameterBuildCubit>(context,
                                  listen: false)
                              .parameterChanged(context, parameter);
                          BlocProvider.of<ComponentCreationCubit>(context,
                                  listen: false)
                              .changedComponent();
                        },
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
        BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
          buildWhen: (state1, state2) {
            if (state2 is ParameterChangeState &&
                (state2).parameter == parameter) return true;
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
                      style:
                          AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
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
                    BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                        .parameterChanged(context, parameter);
                    BlocProvider.of<ComponentCreationCubit>(context,
                            listen: false)
                        .changedComponent();
                  },
                ));
          },
        )
      ],
    );
  }
}

class ColorInputWidget extends StatefulWidget {
  final SimpleParameter parameter;

  const ColorInputWidget({Key? key, required this.parameter}) : super(key: key);

  @override
  State<ColorInputWidget> createState() => _ColorInputWidgetState();
}

class _ColorInputWidgetState extends State<ColorInputWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final GlobalKey _editorKey = GlobalKey();
  final DynamicValueEditingController _textEditingController =
      DynamicValueEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _textEditingController.text = widget.parameter.compiler.code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.parameter.value;
    return Form(
      key: _formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            builder: (context, state) {
              return Row(
                children: [
                  if (!widget.parameter.isRequired)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Checkbox(
                          value: value != null,
                          onChanged: (b) {
                            if (b != null) {
                              if (!b) {
                                widget.parameter.val = null;
                              } else {
                                widget.parameter.val = Colors.transparent;
                              }
                              setState(() {});
                              BlocProvider.of<ParameterBuildCubit>(context,
                                      listen: false)
                                  .parameterChanged(context, widget.parameter);
                              BlocProvider.of<ComponentCreationCubit>(context,
                                      listen: false)
                                  .changedComponent();
                            }
                          }),
                    ),
                  if (value != null)
                    SizedBox(
                      width: 15,
                      child: ColorButton(
                        color: value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.parameter.value ?? Colors.transparent,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        onColorChanged: (color) {
                          widget.parameter.val = color;
                          if (widget.parameter.inputCalculateAs != null) {
                            widget.parameter.val = widget
                                .parameter.inputCalculateAs!
                                .call(widget.parameter.val!, true);
                          }
                          _textEditingController.text = widget
                              .parameter
                              .compiler
                              .code = '#${color.value.toRadixString(16)}';
                          setState(() {});
                          BlocProvider.of<ParameterBuildCubit>(context,
                                  listen: false)
                              .parameterChanged(context, widget.parameter);
                          BlocProvider.of<ComponentCreationCubit>(context,
                                  listen: false)
                              .changedComponent();
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(
            width: 5,
          ),
          SizedBox(
            width: 100,
            child: DynamicValueField<Color>(
              key: _editorKey,
              textEditingController: _textEditingController,
              onErrorCode: (){
                widget.parameter.compiler.code = '';
                widget.parameter.val =null;
                BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                    .parameterChanged(context, widget.parameter);
                BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                    .changedComponent();
              },
              onProcessedResult: (code, result) {
                widget.parameter.compiler.code = code;
                widget.parameter.val = fromHex(result);
                BlocProvider.of<ParameterBuildCubit>(context, listen: false)
                    .parameterChanged(context, widget.parameter);
                BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                    .changedComponent();
                // setState(() {});
                return true;
              },
            ),
          )
        ],
      ),
    );
  }
}

class ChoiceValueListParameterWidget extends StatelessWidget {
  final ChoiceValueListParameter parameter;

  const ChoiceValueListParameterWidget({Key? key, required this.parameter})
      : super(key: key);

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
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
          BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState &&
                  (state2).parameter == parameter) return true;
              return false;
            },
            builder: (context, state) {
              return InkWell(
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
                          data: parameter.options
                              .map((e) => e.toString())
                              .toList(),
                          onSelection: (data) {
                            parameter.val = parameter.options.indexOf(data);
                            BlocProvider.of<ParameterBuildCubit>(context,
                                    listen: false)
                                .parameterChanged(context, parameter);
                            BlocProvider.of<ComponentCreationCubit>(context,
                                    listen: false)
                                .changedComponent();
                          },
                        ),
                      );
                    },
                  );
                },
                /*
                parameter.dynamicChild==null?

                :parameter.dynamicChild!(parameter.value)
                * */
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
                  child: parameter.dynamicChild != null
                      ? parameter.dynamicChild?.call(parameter.value)
                      : Text(
                          parameter.value,
                          style: AppFontStyle.roboto(14,
                              fontWeight: FontWeight.w500),
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

  const ComplexParameterWidget({Key? key, required this.parameter})
      : super(key: key);

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
            style: AppFontStyle.roboto(14,
                color: AppColors.theme.shade700, fontWeight: FontWeight.w800),
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

class BooleanParameterWidget extends StatefulWidget {
  final BooleanParameter parameter;


  const BooleanParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  State<BooleanParameterWidget> createState() => _BooleanParameterWidgetState();
}

class _BooleanParameterWidgetState extends State<BooleanParameterWidget> {
  final TextEditingController _textEditingController=TextEditingController();

  @override
  void initState() {
    super.initState();
  _textEditingController.text=widget.parameter.compiler.code;
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.parameter.displayName!,
            style: AppFontStyle.roboto(14,
                color: Colors.black, fontWeight: FontWeight.w500),
          ),

          SizedBox(
            width: 150,
            child: DynamicValueField<bool>(onProcessedResult: (code,value){
              widget.parameter.compiler.code=code;
              widget.parameter.val=value;
              BlocProvider.of<ParameterBuildCubit>(context,
                  listen: false)
                  .parameterChanged(context, widget.parameter);
              BlocProvider.of<ComponentCreationCubit>(context,
                  listen: false)
                  .changedComponent();
              return true;
            }, textEditingController: _textEditingController),
          )
        ],
      ),
    );
  }
}
