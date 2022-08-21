import 'package:cyclop/cyclop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../bloc/error/error_bloc.dart';
import '../common/compiler/code_processor.dart';
import '../common/custom_drop_down.dart';
import '../common/dialog_selection.dart';
import '../common/dynamic_value_editing_controller.dart';
import '../common/dynamic_value_filed.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../enums.dart';
import '../models/component_model.dart';
import '../models/other_model.dart';
import '../models/parameter_model.dart';
import 'action_code_editor.dart';
import 'common/action_code_dialog.dart';
import 'component_tree.dart';
import 'image_selection.dart';

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
                  fontSize: 12,
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
    //     Provider.of<ComponentSelectionCubit>(context)
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
    } else if (parameter is CodeParameter) {
      return CodeParameterWidget(parameter: parameter as CodeParameter);
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

class CodeParameterWidget extends StatelessWidget {
  final CodeParameter parameter;

  const CodeParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: const Color(0xfff2f2f2),
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(3),
        child: Flex(
          direction: Responsive.isLargeScreen(context)
              ? Axis.vertical
              : Axis.horizontal,
          children: [
            Text(
              parameter.displayName!,
              style: AppFontStyle.roboto(14,
                  color: Colors.black, fontWeight: FontWeight.w500),
            ),
            if (Responsive.isLargeScreen(context)) ...[
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 400,
                child: FVBCodeEditor(
                  scopeName: parameter.displayName ?? '',
                  code: parameter.actionCode,
                  onCodeChange: (code) {
                    parameter.actionCode = code;
                    context.read<ComponentCreationCubit>().changedComponent();
                  },
                  onError: (error) {},
                  processor: ComponentOperationCubit.currentProject!.processor,
                  config: ActionCodeEditorConfig(),
                ),
              )
            ] else ...[
              const Spacer(),
              CustomActionCodeButton(
                title: parameter.displayName ?? '',
                code: () => parameter.actionCode,
                onChanged: (code) {
                  parameter.actionCode = code;
                  context.read<ComponentCreationCubit>().changedComponent();
                },
                processor: ComponentOperationCubit.currentProject!.processor,
                config: ActionCodeEditorConfig(),
                onDismiss: () {},
              )
            ]
          ],
        ));
  }
}

class SimpleParameterWidget extends StatefulWidget {
  final SimpleParameter parameter;

  const SimpleParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  State<SimpleParameterWidget> createState() => _SimpleParameterWidgetState();
}

class _SimpleParameterWidgetState extends State<SimpleParameterWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late ComponentSelectionCubit _componentSelectionCubit;
  late ComponentOperationCubit _componentOperationCubit;
  final DynamicValueEditingController _textEditingController =
      DynamicValueEditingController();
  late CodeProcessor? processor;

  @override
  void initState() {
    super.initState();
    _componentSelectionCubit = context.read<ComponentSelectionCubit>();
    _componentOperationCubit = context.read<ComponentOperationCubit>();
    final root = _componentSelectionCubit.currentSelected.root;
    processor = processorWithComp[
        _componentSelectionCubit.currentSelected.propertySelection.id]??
        (root is CustomComponent
            ? root.processor
            : ComponentOperationCubit.currentProject!.currentScreen.processor);
  }

  @override
  Widget build(BuildContext context) {
    _textEditingController.text = widget.parameter.compiler.code;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: const Color(0xfff2f2f2),
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.parameter.displayName != null)
            Text(
              widget.parameter.displayName!,
              style: AppFontStyle.roboto(14,
                  color: Colors.black, fontWeight: FontWeight.w500),
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
    if (processor == null) {
      return Container();
    }
    switch (widget.parameter.inputType) {
      case ParamInputType.simple:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomActionCodeButton(
                code: () => widget.parameter.compiler.code,
                title: widget.parameter.displayName ?? '',
                onChanged: (value) {
                  widget.parameter.compiler.code = value;
                },
                config: ActionCodeEditorConfig(
                    singleLine: true,
                    parentProcessorGiven: true,
                    string: widget.parameter.type == String ||
                        widget.parameter.type == ImageData),
                processor: processor!,
                onDismiss: () {
                  checkForResult(widget.parameter.compiler.code);
                  BlocProvider.of<ParameterBuildCubit>(context)
                      .parameterChanged(context, widget.parameter);
                  BlocProvider.of<ComponentCreationCubit>(context)
                      .changedComponent();
                }),
            const SizedBox(
              width: 10,
            ),
            Form(
              key: _formKey,
              child: SizedBox(
                width: Responsive.isSmallScreen(context)?120:200,
                height: null,
                child: TextFormField(
                  maxLines: 3,
                  validator: (value) {
                    if (value != null) {
                      return checkForResult(value) ? '' : null;
                    }
                    return null;
                  },
                  buildCounter: (
                    BuildContext context, {
                    required int currentLength,
                    required int? maxLength,
                    required bool isFocused,
                  }) {
                    return Text(
                      '${widget.parameter.val}',
                      style: AppFontStyle.roboto(13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueAccent),
                    );
                  },
                  style: AppFontStyle.roboto(13, fontWeight: FontWeight.w600),
                  controller: _textEditingController,
                  onChanged: (value) {
                    if (value == widget.parameter.compiler.code) {
                      return;
                    }
                    if (value.isNotEmpty || widget.parameter.val is String) {
                      _formKey.currentState!.validate();
                      return;
                    } else {
                      widget.parameter.compiler.code = '';
                      widget.parameter.val = null;
                    }
                    BlocProvider.of<ParameterBuildCubit>(context)
                        .parameterChanged(context, widget.parameter);
                    BlocProvider.of<ComponentCreationCubit>(context)
                        .changedComponent();
                  },
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
            ),
          ],
        );
      case ParamInputType.color:
        return ColorInputWidget(
          parameter: widget.parameter,
          processor: processor!,
          textEditingController: _textEditingController,
        );
      case ParamInputType.sliderZeroToOne:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomActionCodeButton(
                code: () => widget.parameter.compiler.code,
                title: widget.parameter.displayName ?? '',
                onChanged: (value) {
                  widget.parameter.compiler.code = value;
                },
                config: ActionCodeEditorConfig(
                    singleLine: true, parentProcessorGiven: true),
                processor: processor!,
                onDismiss: () {
                  checkForResult(widget.parameter.compiler.code);
                  setState(() {});
                }),
            const SizedBox(
              width: 10,
            ),
            SizedBox(
              width: 120,
              child: DynamicValueField<double>(
                  formKey: _formKey,
                  processor: processor!,
                  inputOption: InputOption.doubleZeroToOne,
                  onProcessedResult: (code, result) {
                    widget.parameter.val = result;
                    BlocProvider.of<ParameterBuildCubit>(context)
                        .parameterChanged(context, widget.parameter);
                    BlocProvider.of<ComponentCreationCubit>(context)
                        .changedComponent();
                    return true;
                  },
                  textEditingController: _textEditingController),
            ),
          ],
        );
      case ParamInputType.image:
        if (_textEditingController.text.isEmpty) {
          if (widget.parameter.compiler.code.isNotEmpty) {
            _textEditingController.text = widget.parameter.compiler.code;
          } else {
            _textEditingController.text =
                (widget.parameter.val as ImageData?)?.imageName ?? '';
          }
        }
        return BlocBuilder<ComponentOperationCubit, ComponentOperationState>(
            builder: (context, state) {
          return StatefulBuilder(builder: (context, setStateForImage) {
            final name = widget.parameter
                .process(widget.parameter.compiler.code, processor: processor!);
            final value = name != null
                ? ImageData(ComponentOperationCubit.bytesCache[name], name)
                : null;
            return InkWell(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (
                      _,
                    ) =>
                        ImageSelectionWidget(
                            componentOperationCubit:
                                BlocProvider.of<ComponentOperationCubit>(
                                    context,
                                    listen: false))).then((value) {
                  if (value != null && value is ImageData) {
                    widget.parameter.val = value;
                    widget.parameter.compiler.code = value.imageName!;
                    _textEditingController.text =
                        widget.parameter.compiler.code;
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
                  value != null && (value.bytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: value.imageName!.endsWith('.svg')
                              ? SvgPicture.memory(
                                  value.bytes!,
                                  width: 40,
                                  fit: BoxFit.fitHeight,
                                )
                              : Image.memory(
                                  value.bytes!,
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
                  CustomActionCodeButton(
                      code: () => widget.parameter.compiler.code,
                      title: widget.parameter.displayName ?? '',
                      onChanged: (value) {
                        widget.parameter.compiler.code = value;
                      },
                      config: ActionCodeEditorConfig(
                        singleLine: true,
                        parentProcessorGiven: true,
                        string: true,
                      ),
                      processor: processor!,
                      onDismiss: () {
                        checkForResult(widget.parameter.compiler.code);
                        _textEditingController.text =
                            widget.parameter.compiler.code;
                      }),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: Responsive.isSmallScreen(context)?120:200,
                    child: DynamicValueField<String>(
                        processor: processor!,
                        formKey: _formKey,
                        onProcessedResult: (code, result) {
                          widget.parameter.compiler.code = code;
                          if (_componentOperationCubit.byteCache[result] !=
                              null) {
                            widget.parameter.val = ImageData(
                                _componentOperationCubit.byteCache[result],
                                result);
                          } else {
                            widget.parameter.val = null;
                          }

                          setStateForImage(() {});

                          BlocProvider.of<ComponentCreationCubit>(context,
                                  listen: false)
                              .changedComponent();
                          return true;
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

  bool checkForResult(String value) {
    dynamic result;
    try {
      result = widget.parameter.process(value, processor: processor);
    } on Exception catch (error) {
      context.read<ErrorBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage(error.toString(), ConsoleMessageType.error)));
      result = null;
    }
    widget.parameter.compiler.code = value;
    if (result is! FVBUndefined) {
      if (widget.parameter.type == double && result.runtimeType == int) {
        widget.parameter.val = (result as int).toDouble();
      } else {
        widget.parameter.val = result;
      }
      if (widget.parameter.inputCalculateAs != null) {
        widget.parameter.val = widget.parameter.inputCalculateAs!
            .call(widget.parameter.val!, true);
      }
    }
    BlocProvider.of<ParameterBuildCubit>(context)
        .parameterChanged(context, widget.parameter);
    BlocProvider.of<ComponentCreationCubit>(context).changedComponent();
    return CodeProcessor.error;
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
                    BlocProvider.of<ParameterBuildCubit>(context)
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
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: (){
                showDialog(
                  barrierDismissible: false,
                  barrierLabel: 'barrierLabel',
                  barrierColor: Colors.black45,
                  builder: (_) {
                    return Material(
                      color: Colors.transparent,
                      child: DialogSelection(
                        title: '${parameter.displayName}',
                        data: parameter.options.keys
                            .map((e) => e.toString())
                            .toList(),
                        onSelection: (data) {
                          parameter.val = data;
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
                  context: context,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${parameter.val??'Select ${parameter.displayName}'}',style:AppFontStyle.roboto(14,fontWeight: FontWeight.normal),),
                    const SizedBox(width: 10,),
                    const Icon(Icons.arrow_drop_down,)
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class ColorInputWidget extends StatefulWidget {
  final SimpleParameter parameter;
  final CodeProcessor processor;
  final DynamicValueEditingController textEditingController;

  const ColorInputWidget(
      {Key? key,
      required this.parameter,
      required this.processor,
      required this.textEditingController})
      : super(key: key);

  @override
  State<ColorInputWidget> createState() => _ColorInputWidgetState();
}

class _ColorInputWidgetState extends State<ColorInputWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey(),
      dynamicFormKey = GlobalKey<FormState>();
  final GlobalKey _editorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
          buildWhen: (state1, state2) {
            if (state2 is ParameterChangeState &&
                state2.parameter == widget.parameter) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            final codeOut = widget.parameter.process(
                widget.parameter.compiler.code,
                processor: widget.processor);
            final value = codeOut != null
                ? hexToColor(codeOut)
                : (widget.parameter.isRequired
                    ? widget.parameter.defaultValue
                    : null);
            return Row(
              children: [
                if (!widget.parameter.isRequired)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Checkbox(
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                        value: widget.parameter.compiler.code.isNotEmpty,
                        onChanged: (b) {
                          if (b != null) {
                            if (!b) {
                              widget.parameter.compiler.code = '';
                            } else {
                              widget.parameter.compiler.code = '#ffffff';
                            }
                            widget.textEditingController.text=widget.parameter.compiler.code;
                            BlocProvider.of<ParameterBuildCubit>(context,
                                    listen: false)
                                .parameterChanged(context, widget.parameter);
                            WidgetsBinding.instance
                                .addPostFrameCallback((timeStamp) {
                              BlocProvider.of<ComponentCreationCubit>(context,
                                      listen: false)
                                  .changedComponent();
                            });
                          }
                        }),
                  ),
                CustomActionCodeButton(
                    code: () => widget.parameter.compiler.code,
                    title: widget.parameter.displayName ?? '',
                    onChanged: (value) {
                      widget.parameter.compiler.code = value;
                    },
                    config: ActionCodeEditorConfig(
                        singleLine: true,
                        parentProcessorGiven: true,
                    ),
                    processor: widget.processor,
                    onDismiss: () {
                      widget.textEditingController.text=widget.parameter.compiler.code ;
                      checkForResult(widget.parameter.compiler.code);
                      BlocProvider.of<ParameterBuildCubit>(context)
                          .parameterChanged(context, widget.parameter);
                      BlocProvider.of<ComponentCreationCubit>(context)
                          .changedComponent();
                    }),
                const SizedBox(
                  width: 10,
                ),
                if (value != null)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: ColorButton(
                      color: value,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: value,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      onColorChanged: (color) {
                        widget.parameter.val = color;
                        if (widget.parameter.inputCalculateAs != null) {
                          widget.parameter.val = widget
                              .parameter.inputCalculateAs!
                              .call(widget.parameter.val!, true);
                        }
                        widget.textEditingController.text = widget
                            .parameter
                            .compiler
                            .code = '#${color.value.toRadixString(16)}';
                        // BlocProvider.of<ParameterBuildCubit>(context,
                        //         listen: false)
                        //     .parameterChanged(context, widget.parameter);
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
            formKey: _formKey,
            key: _editorKey,
            processor: widget.processor,
            textEditingController: widget.textEditingController,
            onProcessedResult: (code, result) {
              widget.parameter.compiler.code = code;
              if (result is String) {
                widget.parameter.val = fromHex(result);
              }
              BlocProvider.of<ParameterBuildCubit>(context)
                  .parameterChanged(context, widget.parameter);
              BlocProvider.of<ComponentCreationCubit>(context)
                  .changedComponent();
              return true;
            },
          ),
        )
      ],
    );
  }
  void checkForResult(String value) {
    dynamic result;
    try {
      result = widget.parameter.process(value, processor: widget.processor);
    } on Exception catch (error) {
      context.read<ErrorBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage(error.toString(), ConsoleMessageType.error)));
      result = null;
    }
    widget.parameter.compiler.code = value;
    if (result is! FVBUndefined && result is String) {
      widget.parameter.val = fromHex(result);
    } else if (result == null && !widget.parameter.isRequired) {
      widget.parameter.val = null;
    }
    BlocProvider.of<ParameterBuildCubit>(context)
        .parameterChanged(context, widget.parameter);
    BlocProvider.of<ComponentCreationCubit>(context).changedComponent();
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
                  showDialog(
                    barrierDismissible: false,
                    barrierLabel: 'barrierLabel',
                    barrierColor: Colors.black45,
                    builder: (_) {
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
                    context: context,
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
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.shimmerColor, width: 1.5)),
      padding: const EdgeInsets.all(5),
      child: StatefulBuilder(builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parameter.displayName != null) ...[
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  if (!parameter.isRequired)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Checkbox(
                        value: parameter.enable,
                        onChanged: (tick) {
                          if (tick != null) {
                            parameter.enable = tick;
                            setState(() {});
                            BlocProvider.of<ComponentCreationCubit>(context)
                                .changedComponent();
                          }
                        },
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  Text(
                    parameter.displayName!,
                    style: AppFontStyle.roboto(14,
                        color: AppColors.theme.shade700,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 5,
            ),
            if (parameter.enable)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final subParam in parameter.params)
                    ParameterWidget(
                      parameter: subParam,
                    )
                ],
              ),
          ],
        );
      }),
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
  final TextEditingController _textEditingController = TextEditingController();
  late CodeProcessor processor;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final _selectionCubit = context.read<ComponentSelectionCubit>();
    final root=_selectionCubit.currentSelectedRoot;
    processor = processorWithComp[
            _selectionCubit.currentSelected.propertySelection.id]??
        (root is CustomComponent
            ? (root).processor
            : ComponentOperationCubit.currentProject!.currentScreen.processor);
  }

  @override
  Widget build(BuildContext context) {
    _textEditingController.text = widget.parameter.compiler.code;
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              widget.parameter.displayName!,
              style: AppFontStyle.roboto(14,
                  color: Colors.black, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomActionCodeButton(
                  code: () => widget.parameter.compiler.code,
                  title: widget.parameter.displayName ?? '',
                  onChanged: (value) {
                    widget.parameter.compiler.code = value;
                  },
                  config: ActionCodeEditorConfig(
                    singleLine: true,
                    parentProcessorGiven: true,
                  ),
                  processor: processor,
                  onDismiss: () {
                    checkForResult(widget.parameter.compiler.code);
                    setState(() {});
                  }),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 150,
                child: DynamicValueField<bool>(
                    formKey: _formKey,
                    processor: processor,
                    onProcessedResult: (code, value) {
                      widget.parameter.compiler.code = code;
                      if (value is! FVBUndefined) {
                        if (value != null || !widget.parameter.isRequired) {
                          widget.parameter.val = value;
                          BlocProvider.of<ParameterBuildCubit>(context)
                              .parameterChanged(context, widget.parameter);
                          BlocProvider.of<ComponentCreationCubit>(context,
                                  listen: false)
                              .changedComponent();
                        }
                      }
                      return true;
                    },
                    textEditingController: _textEditingController),
              ),
            ],
          )
        ],
      ),
    );
  }

  void checkForResult(String value) {
    dynamic result;
    try {
      result = widget.parameter.process(value, processor: processor);
    } on Exception catch (error) {
      context.read<ErrorBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage(error.toString(), ConsoleMessageType.error)));
      result = null;
    }
    widget.parameter.compiler.code = value;
    if (result is! FVBUndefined && result is bool) {
      widget.parameter.val = result;
    } else if (result == null && !widget.parameter.isRequired) {
      widget.parameter.val = null;
    }
    BlocProvider.of<ParameterBuildCubit>(context)
        .parameterChanged(context, widget.parameter);
    BlocProvider.of<ComponentCreationCubit>(context).changedComponent();
  }
}
/*
  return SizedBox(
          width:
          widget.parameter.inputType == ParamInputType.text ? 110 : 200,
          height:
          widget.parameter.inputType != ParamInputType.text ? 60 : 50,
          child: ActionCodeEditor(code:widget.parameter.compiler.code , onCodeChange: (value){
            if (value.isNotEmpty || widget.parameter.val is String) {
              checkForResult(value);
              return;
            } else {
              widget.parameter.compiler.code = '';
              widget.parameter.val = null;
            }
            BlocProvider.of<ParameterBuildCubit>(context)
                .parameterChanged(context, widget.parameter);
            BlocProvider.of<ComponentCreationCubit>(context)
                .changedComponent();
          }, prerequisites: [], variables:()=>[], onError: (eror){}
              , scopeName: widget.parameter.info?.getName()??'', functions: [], config: ActionCodeEditorConfig()),
        );
* */
