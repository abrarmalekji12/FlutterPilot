import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../bloc/error/error_bloc.dart';
import '../collections/project_info_collection.dart';
import '../common/app_button.dart';
import '../common/app_switch.dart';
import '../common/app_tooltip.dart';
import '../common/color/color_picker.dart';
import '../common/converter/string_operation.dart';
import '../common/custom_extension_tile.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/dialog_selection.dart';
import '../common/dynamic_value_editing_controller.dart';
import '../common/extension_util.dart';
import '../common/package/custom_textfield_searchable.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/other_constant.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/parameter_build_cubit/parameter_build_cubit.dart';
import '../enums.dart';
import '../injector.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/fvb_ui_core/component/custom_component.dart';
import '../models/input_types/range_input.dart';
import '../models/other_model.dart';
import '../models/parameter_model.dart';
import '../models/project_model.dart';
import '../widgets/overlay/overlay_manager.dart';
import 'component_tree/component_tree.dart';
import 'fvb_code_editor.dart';
import 'image_selection.dart';
import 'navigation/animated_dialog.dart';
import 'navigation/animated_slider.dart';

mixin GetProcessor {
  final UserProjectCollection _collection = sl<UserProjectCollection>();

  Processor needfulProcessor(SelectionCubit _componentSelectionCubit,
      {Parameter? parameter}) {
    if (parameter is UsableParam &&
        (parameter as UsableParam).usableName != null) {
      return _collection.project!.processor;
    }
    final root = _componentSelectionCubit.currentSelectedRoot;
    final selected = _componentSelectionCubit.selected;
    if (processorWithComp[selected.propertySelection.id] != null) {
      return processorWithComp[selected.propertySelection.id]!;
    }

    if (root is CustomComponent) {
      return root.processor;
    }
    final parent =
        selected.propertySelection.parentProcessor(selected.viewable, root);
    if (parent != null) {
      return parent;
    }
    if (selected.visualSelection.isNotEmpty) {
      final parent = selected.visualSelection.first
          .parentProcessor(selected.viewable, root);
      if (parent != null) {
        return parent;
      }
    }
    if (_componentSelectionCubit.selected.viewable != null) {
      return _componentSelectionCubit.selected.viewable!.processor;
    }
    return _collection.project!.processor;
  }
}

class ComponentUpdateProcessorNotifier extends StatelessWidget {
  final Widget child;
  final VoidCallback onUpdate;

  const ComponentUpdateProcessorNotifier(
      {Key? key, required this.child, required this.onUpdate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreationCubit, CreationState>(
      listener: (_, state) {
        if (state is ComponentCreationChangeState) {
          onUpdate.call();
        }
      },
      child: child,
    );
  }
}

final OperationCubit _operationCubit = sl();
final ParameterBuildCubit _parameterCubit = sl();

class ChoiceParameterWidget extends StatelessWidget {
  final ChoiceParameter parameter;

  const ChoiceParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parameter.displayName != null) ...[
          Text(
            parameter.displayName!,
            style: TextStyle(
                fontSize: 14,
                color: theme.text1Color,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(
            height: 5,
          ),
        ],
        BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
          buildWhen: (state1, state2) {
            if (state2 is ParameterChangeState &&
                state2.parameter == parameter) {
              return true;
            }
            return false;
          },
          builder: (context, state) {
            final selected = parameter.rawValue;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    for (final subParam in parameter.options)
                      Container(
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.only(right: 4, bottom: 4),
                        child: SizedBox(
                          height: 23,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Radio<Parameter>(
                                activeColor: ColorAssets.theme,
                                value: selected,
                                groupValue: subParam,
                                onChanged: (value) {
                                  _operationCubit.reversibleParameterOperation(
                                      parameter.val, () {
                                    parameter.updateParam(subParam);
                                    _parameterCubit.parameterChanged(parameter);
                                  }, (p0, component) {
                                    parameter.updateParam(p0);
                                    _parameterCubit.parameterChanged(parameter,
                                        component: component);
                                  });
                                },
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              if (subParam.displayName != null)
                                Flexible(
                                  child: Text(
                                    subParam.displayName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.text1Color,
                                      fontWeight: parameter.rawValue == subParam
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
                if (selected is! NullParameter) ...[
                  const SizedBox(
                    height: 5,
                  ),
                  ParameterWidget(
                    parameter: selected,
                  )
                ]
              ],
            );
          },
        ),
      ],
    );
  }
}

class ParameterWidget extends StatefulWidget {
  final Parameter? parameter;

  const ParameterWidget({Key? key, this.parameter}) : super(key: key);

  @override
  State<ParameterWidget> createState() => _ParameterWidgetState();
}

final UserProjectCollection _collection = sl<UserProjectCollection>();

class _ParameterWidgetState extends State<ParameterWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.parameter == null) return Container();
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
    final Parameter? param;
    if (widget.parameter is UsableParam &&
        (widget.parameter as UsableParam).usableName != null) {
      param = _collection.project!.commonParams
              .firstWhereOrNull((element) =>
                  element.name == (widget.parameter as UsableParam).usableName)
              ?.parameter ??
          widget.parameter;
    } else {
      param = widget.parameter;
    }
    final b = widget.parameter is UsableParam &&
        (widget.parameter as UsableParam).reused;
    return FractionallySizedBox(
      widthFactor: widget.parameter?.config?.width != null
          ? widget.parameter!.config!.width!
          : null,
      child: Padding(
        padding: widget.parameter?.config?.width != null
            ? const EdgeInsets.only(right: 4)
            : EdgeInsets.zero,
        child: Stack(
          key: widget.parameter != null
              ? GlobalObjectKey(widget.parameter!)
              : null,
          children: [
            Container(
              decoration: b
                  ? BoxDecoration(
                      border: Border.all(
                          color: ColorAssets.theme.withOpacity(0.3),
                          width: 1.4),
                      color: ColorAssets.theme.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10))
                  : null,
              padding: b ? const EdgeInsets.all(4) : EdgeInsets.zero,
              child: Builder(builder: (_) {
                if (param is SimpleParameter) {
                  return SimpleParameterWidget(parameter: param);
                } else if (param is ChoiceValueListParameter) {
                  return ChoiceValueListParameterWidget(parameter: param);
                } else if (param is ListParameter) {
                  return ListParameterWidget(parameter: param);
                } else if (param is CodeParameter) {
                  return CodeParameterWidget(parameter: param);
                }
                switch (param.runtimeType) {
                  case ChoiceParameter:
                    return ChoiceParameterWidget(
                      parameter: param as ChoiceParameter,
                    );
                  case ComplexParameter:
                    return ComplexParameterWidget(
                      parameter: param as ComplexParameter,
                    );
                  case ChoiceValueParameter:
                    return ChoiceValueParameterWidget(
                        parameter: param as ChoiceValueParameter);
                  case BooleanParameter:
                    return BooleanParameterWidget(
                        parameter: param as BooleanParameter);

                  default:
                    return Container();
                }
              }),
            ),
            if (widget.parameter is UsableParam &&
                (widget.parameter is! ComplexParameter ||
                    (widget.parameter as ComplexParameter).params.length > 1))
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3, right: 3),
                  child: UsableParameterWidget(
                    param: widget.parameter as UsableParam,
                    update: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UsableParameterWidget extends StatefulWidget {
  final UsableParam param;
  final VoidCallback update;

  const UsableParameterWidget(
      {Key? key, required this.param, required this.update})
      : super(key: key);

  @override
  State<UsableParameterWidget> createState() => _UsableParameterWidgetState();
}

enum UsableParamState { initial, saved, connected, lookUpState }

class _UsableParameterWidgetState extends State<UsableParameterWidget>
    with OverlayManager {
  UsableParamState _paramState = UsableParamState.initial;
  final GlobalKey _key = GlobalKey();
  final UserProjectCollection _collection = sl<UserProjectCollection>();

  late TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    if (widget.param.usableName != null) {
      if (_collection.project!.commonParams.firstWhereOrNull(
              (element) => element.parameter == (widget.param as Parameter)) !=
          null) {
        _paramState = UsableParamState.saved;
      } else {
        _paramState = UsableParamState.connected;
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      padding: const EdgeInsets.only(top: 3, right: 3),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_paramState == UsableParamState.initial) ...[
              TooltipWidget(
                message: 'Common Across Project',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    showCommonUpdateOverlay();
                  },
                  child: Icon(
                    Icons.circle_rounded,
                    color: ColorAssets.green.withOpacity(0.6),
                    size: 6,
                  ),
                ),
              )
            ] else if (_paramState == UsableParamState.saved ||
                _paramState == UsableParamState.connected) ...[
              Builder(builder: (context) {
                bool expand = false;
                return StatefulBuilder(builder: (context, setState2) {
                  return InkWell(
                    onTap: () {
                      setState2(() {
                        expand = !expand;
                      });
                    },
                    child: expand
                        ? Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: theme.background1,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  )
                                ],
                                border: Border.all(
                                    color: _paramState ==
                                            UsableParamState.connected
                                        ? ColorAssets.green
                                        : ColorAssets.theme.withOpacity(0.8),
                                    width: 1)),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState2(() {
                                      expand = false;
                                    });
                                  },
                                  child: const Icon(
                                    Icons.arrow_right_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                4.wBox,
                                Text(
                                  widget.param.usableName ?? '',
                                  style: AppFontStyle.lato(13,
                                      color: theme.text1Color,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: widget.param.usableName!));
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                InkWell(
                                  onTap: () {
                                    _controller.text =
                                        widget.param.usableName ?? '';
                                    showCommonUpdateOverlay();
                                  },
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: ColorAssets.theme,
                                  ),
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      widget.param.usableName = null;
                                      final exist = _collection
                                          .project!.commonParams
                                          .firstWhereOrNull((element) =>
                                              element.name ==
                                              widget.param.usableName);
                                      if (exist != null) {
                                        final id = context
                                            .read<SelectionCubit>()
                                            .selected
                                            .intendedSelection
                                            .id;
                                        exist.connected.removeWhere(
                                            (comp) => comp.id == id);
                                        if (exist.connected.isEmpty) {
                                          _collection.project!.commonParams
                                              .remove(exist);
                                        }
                                      }
                                      widget.update.call();
                                      context
                                          .read<CreationCubit>()
                                          .changedComponent();
                                      _paramState = UsableParamState.initial;
                                    });
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    size: 14,
                                    color: theme.iconColor1,
                                  ),
                                )
                              ],
                            ),
                          )
                        : const CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.blueAccent,
                          ),
                  );
                });
              })
            ],
          ],
        ),
      ),
    );
  }

  void showCommonUpdateOverlay() {
    final _createNew = TileModel('Create new', '', sticky: true, onTap: () {});
    final list = [
      ..._collection.project!.commonParams
          .where(
              (element) => element.parameter.isEqual(widget.param as Parameter))
          .map((e) => TileModel(e.name, e.name, onDelete: () {
                _collection.project!.commonParams.remove(e);
              })),
      _createNew
    ];
    showOverlay(
        context,
        'common',
        (p0, p1) {
          final position = _key.position!;
          return Positioned(
            right: MediaQuery.of(context).size.width - position.dx - 10,
            bottom: MediaQuery.of(context).size.height - position.dy + 15,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.background1,
                  boxShadow: kElevationToShadow[2],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: CustomTextFieldSearch(
                          initialList: list,
                          itemsInView: list.length,
                          controller: _controller,
                          decoration: InputDecoration(
                            focusColor: ColorAssets.theme,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1, color: theme.text1Color)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 1,
                                color: ColorAssets.theme,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1, color: theme.text1Color)),
                          ),
                          label: 'Search Parameter',
                          textStyle:
                              AppFontStyle.lato(12.5, color: theme.text1Color),
                          onSelected: (TileModel tile) {
                            _onSelected();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    AppIconButton(
                      icon: Icons.save,
                      background: ColorAssets.theme,
                      iconColor: Colors.white,
                      onPressed: _onSelected,
                      size: 16,
                      margin: 4,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    AppIconButton(
                      icon: Icons.delete,
                      background: ColorAssets.red,
                      iconColor: Colors.white,
                      onPressed: () {
                        removeOverlay('common');
                        setState(() {
                          widget.param.usableName = null;
                          widget.update.call();

                          _parameterCubit
                              .parameterChanged(widget.param as Parameter);
                          _paramState = UsableParamState.initial;
                        });
                      },
                      size: 16,
                      margin: 4,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideX(
              duration: const Duration(milliseconds: 150), begin: 1, end: 0);
        },
        dismissible: true,
        onRemove: () {
          removeOverlay('common');
        });
  }

  void _onSelected() {
    if (!_controller.text.contains(' ') &&
        !_controller.text.contains('.') &&
        _controller.text.isNotEmpty &&
        widget.param.usableName != _controller.text) {
      final oldName = widget.param.usableName;
      if (oldName != null) {
        _collection.project!.commonParams
            .removeWhere((element) => element.parameter == widget.param);
      }
      widget.param.usableName = _controller.text;
      final exist = _collection.project!.commonParams.firstWhereOrNull(
          (element) => element.name == widget.param.usableName);
      final selection =
          context.read<SelectionCubit>().selected.intendedSelection;
      if (exist != null) {
        exist.connected.add(selection);
        setState(() {
          _paramState = UsableParamState.connected;
        });
      } else {
        final common =
            CommonParam((widget.param as Parameter), widget.param.usableName!);
        _collection.project!.commonParams.add(common);
        if (!common.connected.contains(selection)) {
          common.connected.add(selection);
        }

        setState(() {
          _paramState = UsableParamState.saved;
        });
      }
      removeOverlay('common');
      _parameterCubit.parameterChanged(widget.param as Parameter);
      widget.update.call();
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
            color: theme.border1, borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(3),
        child: Flex(
          direction:
              Responsive.isDesktop(context) ? Axis.vertical : Axis.horizontal,
          children: [
            Text(
              parameter.displayName!,
              style: AppFontStyle.lato(14,
                  color: theme.text1Color, fontWeight: FontWeight.w500),
            ),
            if (Responsive.isDesktop(context)) ...[
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 400,
                child: FVBCodeEditor(
                  code: parameter.actionCode,
                  onCodeChange: (code, refresh) {
                    parameter.actionCode = code;
                    if (refresh)
                      context.read<CreationCubit>().changedComponent();
                  },
                  onErrorUpdate: (message, error) {
                    final selectionCubit = context.read<SelectionCubit>();
                    selectionCubit.updateError(
                        selectionCubit.selected.intendedSelection,
                        message,
                        AnalysisErrorType.parameter,
                        param: parameter);
                  },
                  processor: _collection.project!.processor,
                  config: FVBEditorConfig(),
                ),
              )
            ] else ...[
              const Spacer(),
              CustomActionCodeButton(
                size: 14,
                margin: 5,
                title: parameter.displayName ?? '',
                code: () => parameter.actionCode,
                onChanged: (code, refresh) {
                  parameter.actionCode = code;
                  if (refresh) context.read<CreationCubit>().changedComponent();
                },
                processor: _collection.project!.processor,
                config: FVBEditorConfig(),
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
  final DynamicValueEditingController _textEditingController =
      DynamicValueEditingController();
  late Processor? processor;
  final Debounce _debounce =
      Debounce(const Duration(milliseconds: debounceTimeInMillis));
  late SelectionCubit selectionCubit;
  late ParameterBuildCubit parameterBuildCubit;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    selectionCubit = context.read<SelectionCubit>();
    parameterBuildCubit = _parameterCubit;
    _textEditingController.text = widget.parameter.compiler.code;
  }

  @override
  void didChangeDependencies() {
    processor = ProcessorProvider.maybeOf(context)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ParameterBuildCubit, ParameterBuildState>(
      listener: (context, state) {
        _textEditingController.text = widget.parameter.compiler.code;
      },
      listenWhen: (state1, state2) {
        return state2 is ParameterAlteredState &&
            state2.parameter == widget.parameter;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!widget.parameter.isRequired &&
                  (widget.parameter.type != Color)) ...[
                Checkbox(
                  value: widget.parameter.enable,
                  onChanged: (value) {
                    _operationCubit.reversibleParameterOperation(
                        widget.parameter.enable, () {
                      widget.parameter.enable = !widget.parameter.enable;
                      parameterBuildCubit.parameterChanged(widget.parameter);
                      setState(() {});
                    }, (p0, component) {
                      widget.parameter.enable = p0;
                      parameterBuildCubit.parameterChanged(widget.parameter,
                          component: component);
                      setState(() {});
                    });
                  },
                ),
                const SizedBox(
                  width: 5,
                ),
              ],
              if ((widget.parameter.config?.labelVisible ?? true) &&
                  widget.parameter.displayName != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Tooltip(
                    message: widget.parameter.displayName!,
                    child: Text(
                      widget.parameter.displayName!,
                      overflow: TextOverflow.ellipsis,
                      style: AppFontStyle.lato(
                        13,
                        color: theme.text1Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (widget.parameter.config?.icon != null)
                Icon(
                  widget.parameter.config!.icon!,
                  size: 20,
                ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: _buildInputType(context),
                ),
              )
            ],
          ),
          if (widget.parameter.options is RangeInput)
            StatefulBuilder(builder: (context, setState2) {
              final value = widget.parameter.value;
              final range = (widget.parameter.options! as RangeInput);

              /// TODO: Implement Undo
              if (value != null)
                return SizedBox(
                  height: 10,
                  child: Slider(
                    thumbColor: ColorAssets.theme,
                    activeColor: ColorAssets.theme,
                    value: value,
                    divisions:
                        (range.start is int) ? (range.end - range.start) : null,
                    onChanged: (value) {
                      setState2(() {});
                      widget.parameter.compiler.code = (range.start is int)
                          ? value.toInt().toString()
                          : value.toStringAsFixed(2);
                      _textEditingController.text =
                          widget.parameter.compiler.code;

                      _debounce.run(() {
                        parameterBuildCubit.parameterChanged(widget.parameter);
                      });
                    },
                    min: range.start as double,
                    max: range.end as double,
                  ),
                );
              else
                return const Offstage();
            })
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
            const SizedBox(
              width: 5,
            ),

            // CustomActionCodeButton(
            //     code: () => widget.parameter.compiler.code,
            //     title: widget.parameter.displayName ?? '',
            //     onChanged: (value) {
            //       widget.parameter.compiler.code = value;
            //       _textEditingController.text = value;
            //     },
            //     config: ActionCodeEditorConfig(
            //         singleLine: true,
            //         parentProcessorGiven: true,
            //         string: widget.parameter.type == String ||
            //             widget.parameter.type == ImageData),
            //     processor: processor!,
            //     onDismiss: () {
            //       checkForResult(widget.parameter.compiler.code);
            //     }),
            // const SizedBox(
            //   width: 10,
            // ),
            Expanded(
              child: SizedBox(
                width: Responsive.isMobile(context) ? 120 : 200,
                child: FVBCodeEditor(
                    controller: _textEditingController,
                    code: widget.parameter.compiler.code,
                    onCodeChange: (value, refresh) {
                      widget.parameter.compiler.code = value;
                      if (!widget.parameter.enable && value.isNotEmpty) {
                        widget.parameter.enable = true;
                        setState(() {});
                      }
                      _debounce.run(() {
                        parameterBuildCubit.parameterChanged(widget.parameter,
                            refresh: refresh);
                      });
                    },
                    onErrorUpdate: (message, error) {
                      selectionCubit.updateError(
                          selectionCubit.selected.intendedSelection,
                          message,
                          AnalysisErrorType.parameter,
                          param: widget.parameter);
                    },
                    config: FVBEditorConfig(
                      parentProcessorGiven: true,
                      smallBottomBar: true,
                      multiline: false,
                      shrink: true,
                      returnType: DataType.ofType(widget.parameter.type),
                      string: widget.parameter.type == String ||
                          widget.parameter.type == FVBImage,
                    ),
                    processor: processor!),
              ),
            )
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
            SizedBox(
              width: 120,
              child: FVBCodeEditor(
                  controller: _textEditingController,
                  code: widget.parameter.compiler.code,
                  onCodeChange: (value, refresh) {
                    _debounce.run(() {
                      checkForResult(value);

                      _parameterCubit.parameterChanged(widget.parameter,
                          refresh: refresh);
                    });
                  },
                  onErrorUpdate: (message, error) {
                    selectionCubit.updateError(
                        selectionCubit.selected.intendedSelection,
                        message,
                        AnalysisErrorType.parameter,
                        param: widget.parameter);
                  },
                  config: FVBEditorConfig(
                      parentProcessorGiven: true,
                      smallBottomBar: true,
                      multiline: false,
                      shrink: true,
                      returnType: DataType.ofType(widget.parameter.type),
                      string: widget.parameter.type == String ||
                          widget.parameter.type == FVBImage),
                  processor: processor!),
            ),
          ],
        );
      case ParamInputType.image:
        if (_textEditingController.text.isEmpty) {
          if (widget.parameter.compiler.code.isNotEmpty) {
            _textEditingController.text = widget.parameter.compiler.code;
          } else {
            _textEditingController.text =
                (widget.parameter.val as FVBImage?)?.name ?? '';
          }
        }
        return BlocBuilder<OperationCubit, OperationState>(
            builder: (context, state) {
          return StatefulBuilder(builder: (context, setStateForImage) {
            final name = widget.parameter
                .process(widget.parameter.compiler.code,
                    processor: processor!,
                    component: selectionCubit.selected.intendedSelection)
                .value;
            final value = name != null
                ? FVBImage(bytes: byteCache[name], name: name)
                : null;
            return InkWell(
              onTap: _selectImage,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  value != null && (value.bytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: value.name!.endsWith('.svg')
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
                  // CustomActionCodeButton(
                  //     code: () => widget.parameter.compiler.code,
                  //     title: widget.parameter.displayName ?? '',
                  //     onChanged: (value, refresh) {
                  //       widget.parameter.compiler.code = value;
                  //       _textEditingController.text = value;
                  //     },
                  //     config: ActionCodeEditorConfig(
                  //       singleLine: true,
                  //       parentProcessorGiven: true,
                  //       string: true,
                  //     ),
                  //     processor: processor!,
                  //     onDismiss: () {
                  //       checkForResult(widget.parameter.compiler.code);
                  //       _textEditingController.text =
                  //           widget.parameter.compiler.code;
                  //     }),
                  // const SizedBox(
                  //   width: 10,
                  // ),
                  Expanded(
                    child: SizedBox(
                      width: Responsive.isMobile(context) ? 120 : 200,
                      child: FVBCodeEditor(
                          controller: _textEditingController,
                          code: widget.parameter.compiler.code,
                          onCodeChange: (code, refresh) {
                            _debounce.run(() {
                              widget.parameter.compiler.code = code;
                              // if (_componentOperationCubit.byteCache[result] !=
                              //     null) {
                              //   widget.parameter.val = ImageData(
                              //       _componentOperationCubit.byteCache[result],
                              //       result);
                              // } else {
                              //   widget.parameter.val = null;
                              // }
                              _parameterCubit.parameterChanged(widget.parameter,
                                  refresh: refresh);
                            });
                          },
                          onErrorUpdate: (message, error) {
                            selectionCubit.updateError(
                                selectionCubit.selected.intendedSelection,
                                message,
                                AnalysisErrorType.parameter,
                                param: widget.parameter);
                          },
                          config: FVBEditorConfig(
                              parentProcessorGiven: true,
                              smallBottomBar: true,
                              shrink: true,
                              multiline: false,
                              string: true),
                          processor: processor!),
                    ),
                  )
                  // SizedBox(
                  //   width: Responsive.isSmallScreen(context) ? 120 : 200,
                  //   child: DynamicValueField<String>(
                  //       processor: processor!,
                  //       formKey: _formKey,
                  //       onProcessedResult: (code, result) {
                  //         if (timer?.isActive ?? false) {
                  //           timer?.cancel();
                  //         }
                  //         timer = Timer(const Duration(milliseconds: 300), () {
                  //           widget.parameter.compiler.code = code;
                  //           if (_componentOperationCubit.byteCache[result] !=
                  //               null) {
                  //             widget.parameter.val = ImageData(
                  //                 _componentOperationCubit.byteCache[result],
                  //                 result);
                  //           } else {
                  //             widget.parameter.val = null;
                  //           }
                  //
                  //           setStateForImage(() {});
                  //
                  //           BlocProvider.of<ComponentCreationCubit>(context,
                  //                   listen: false)
                  //               .changedComponent();
                  //         });
                  //
                  //         return true;
                  //       },
                  //       textEditingController: _textEditingController),
                  // )
                ],
              ),
            );
          });
        });
    }
  }

  bool checkForResult(String value) {
    FVBCacheValue? result;
    try {
      result = widget.parameter.process(
        value,
        processor: processor,
        component: context.read<SelectionCubit>().selected.intendedSelection,
      );
    } on Exception {
      // ConsoleMessage(error.toString(), ConsoleMessageType.error);
      result = null;
    }
    widget.parameter.compiler.code = value;
    if (result?.value is! FVBUndefined) {
      if (widget.parameter.type == double && result?.value.runtimeType == int) {
        widget.parameter.val = (result?.value as int).toDouble();
      } else if (result?.value?.runtimeType == widget.parameter.type) {
        widget.parameter.val = result?.value;
      }

      if (widget.parameter.inputCalculateAs != null) {
        widget.parameter.val = widget.parameter.inputCalculateAs!
            .call(widget.parameter.val!, true);
      }
      if (widget.parameter.inputType == ParamInputType.sliderZeroToOne) {
        return Processor.error;
      }
    }
    _parameterCubit.parameterChanged(widget.parameter);
    return Processor.error;
  }

  void _selectImage() {
    AnimatedDialog.show(
        context,
        Container(
          width: 600,
          height: 600,
          decoration: BoxDecoration(
            borderRadius: 10.borderRadius,
            color: theme.background1,
          ),
          child: ImageSelectionWidget(
              onSelected: (value) {
                widget.parameter.val = value;
                widget.parameter.compiler.code = value.name!;
                _textEditingController.text = widget.parameter.compiler.code;
                _parameterCubit.parameterChanged(widget.parameter);
              },
              operationCubit:
                  BlocProvider.of<OperationCubit>(context, listen: false)),
        ));
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
        return Container(
          decoration: BoxDecoration(
              color: theme.background3.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parameter.displayName != null) ...[
                Text(
                  parameter.displayName!,
                  style: TextStyle(
                      fontSize: 15,
                      color: theme.text1Color,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 4,
                ),
              ],
              for (int i = 0; i < parameter.params.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CustomExpansionTile(
                    collapsedBackgroundColor: theme.background1,
                    backgroundColor: theme.background1,
                    title: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${i + 1}',
                            style: AppFontStyle.lato(
                              14,
                              color: theme.text1Color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _operationCubit.reversibleParameterOperation(
                                  parameter.params[i], () {
                                parameter.params.removeAt(i);
                                _parameterCubit.parameterChanged(parameter);
                              }, (p0, component) {
                                parameter.params.insert(i, p0);
                                _parameterCubit.parameterChanged(parameter,
                                    component: component);
                              });
                            },
                            child: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                          )
                        ],
                      ),
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: theme.background1,
                            border: Border(
                              top: BorderSide(
                                color: theme.border1,
                                width: 1.5,
                              ),
                              bottom: BorderSide(
                                color: theme.border1,
                                width: 1.5,
                              ),
                            )),
                        child: ParameterWidget(
                          parameter: parameter.params[i],
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: () {
                  _operationCubit.reversibleParameterOperation(null, () {
                    parameter.params.add(parameter.parameterGenerator());
                    _parameterCubit.parameterChanged(parameter);
                  }, (p0, component) {
                    parameter.params.removeLast();
                    _parameterCubit.parameterChanged(parameter,
                        component: component);
                  });
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.add,
                      color: ColorAssets.theme,
                      size: 24,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Add',
                      style: AppFontStyle.lato(14, color: ColorAssets.theme),
                    )
                  ],
                ),
              ),
            ],
          ),
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
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          if (parameter.displayName != null &&
              (parameter.config?.labelVisible ?? true))
            Text(
              parameter.displayName!,
              style: TextStyle(
                  fontSize: 14,
                  color: theme.text1Color,
                  fontWeight: FontWeight.bold),
            ),
          BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
            buildWhen: (state1, state2) {
              if (state2 is ParameterChangeState &&
                  (state2).parameter == parameter) return true;
              return false;
            },
            builder: (context, state) {
              final value = parameter.rawValue;
              final name =
                  '${(value != null ? StringOperation.toNormalCase(value) : null) ?? 'Select ${parameter.displayName}'}';
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  openDialog(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!parameter.isRequired) ...[
                      Checkbox(
                        value: parameter.val != null,
                        onChanged: (value) {
                          if (value == false) {
                            _operationCubit.reversibleParameterOperation(
                                parameter.val, () {
                              parameter.val = null;
                              _parameterCubit.parameterChanged(parameter);
                              context.read<CreationCubit>().changedComponent();
                            }, (p0, component) {
                              parameter.val = p0;
                              _parameterCubit.parameterChanged(parameter,
                                  component: component);
                              context.read<CreationCubit>().changedComponent();
                            });
                          } else {
                            openDialog(context);
                          }
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                    CustomPopupMenuButton(
                      itemBuilder: (context) {
                        return parameter.options.keys
                            .map(
                              (e) => CustomPopupMenuItem(
                                value: e,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (parameter.getClue != null) ...[
                                      parameter.getClue!
                                          .call(parameter.options[e]),
                                      const SizedBox(
                                        width: 10,
                                      )
                                    ],
                                    Expanded(
                                      child: Text(
                                        StringOperation.toNormalCase(e),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList();
                      },
                      onSelected: (value) {
                        _operationCubit
                            .reversibleParameterOperation(parameter.val, () {
                          parameter.val = value;
                          _parameterCubit.parameterChanged(parameter);
                        }, (p0, component) {
                          parameter.val = p0;
                          _parameterCubit.parameterChanged(parameter,
                              component: component);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              width: 0.6, color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(5),
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (parameter.getClue != null &&
                                parameter.val != null) ...[
                              parameter.getClue!.call(
                                parameter.options[parameter.val!],
                              ),
                              const SizedBox(
                                width: 5,
                              )
                            ],
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                style: AppFontStyle.lato(
                                  12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            )
                          ],
                        ),
                      ),
                    ),
                    /*Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(width: 0.6, color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${(value != null ? StringOperation.toNormalCase(value) : null) ?? 'Select ${parameter.displayName}'}',
                              style: AppFontStyle.roboto(13,
                                  fontWeight: FontWeight.normal),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          )
                        ],
                      ),
                    ),*/
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void openDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      barrierLabel: 'barrierLabel',
      barrierColor: Colors.black45,
      builder: (_) {
        return Material(
          color: Colors.transparent,
          child: DialogSelection(
            title: '${parameter.displayName}',
            getClue: parameter.getClue != null
                ? (key, _) {
                    return parameter.getClue!.call(parameter.options[key]);
                  }
                : null,
            data: parameter.options.keys
                .map<MapEntry<String, String>>((e) => MapEntry<String, String>(
                    StringOperation.toNormalCase(e), e))
                .toList(),
            onSelection: (data) {
              _operationCubit.reversibleParameterOperation(parameter.val, () {
                parameter.val = data.value;
                _parameterCubit.parameterChanged(parameter);
              }, (p0, component) {
                parameter.val = p0;
                _parameterCubit.parameterChanged(parameter,
                    component: component);
              });
            },
          ),
        );
      },
      context: context,
    );
  }
}

class ColorInputWidget extends StatefulWidget {
  final SimpleParameter parameter;
  final Processor processor;
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
  final GlobalKey<FormState> dynamicFormKey = GlobalKey<FormState>();
  final Debounce _debounce =
      Debounce(const Duration(milliseconds: debounceTimeInMillis));

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
            final outputCache = widget.parameter.process(
              widget.parameter.compiler.code,
              processor: widget.processor,
              component:
                  context.read<SelectionCubit>().selected.intendedSelection,
            );
            final output = outputCache.value ?? widget.parameter.defaultValue;
            Color? value;
            if (output is FVBInstance) {
              value = output.toDart();
            } else if (output is Color) {
              value = output;
            }
            return Row(
              children: [
                if (!widget.parameter.isRequired)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 20,
                    height: 20,
                    child: Checkbox(
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                        value: widget.parameter.enable,
                        onChanged: (b) {
                          if (b != null) {
                            _operationCubit.reversibleParameterOperation(
                                widget.parameter.compiler.code, () {
                              if (!b) {
                                widget.parameter.compiler.code = '';
                              } else {
                                widget.parameter.compiler.code = widget
                                            .parameter.defaultValue !=
                                        null
                                    ? 'Color(0x${(widget.parameter.defaultValue as Color).value.toRadixString(16)})'
                                    : 'Colors.white';
                              }
                              widget.parameter.enable = b;
                              widget.textEditingController.text =
                                  widget.parameter.compiler.code;
                              _parameterCubit
                                  .parameterChanged(widget.parameter);
                            }, (p0, component) {
                              widget.parameter.compiler.code = p0;
                              widget.parameter.enable =
                                  (p0 as String).isNotEmpty;
                              widget.textEditingController.text =
                                  widget.parameter.compiler.code;
                              _parameterCubit.parameterChanged(widget.parameter,
                                  component: component);
                            });
                          }
                        }),
                  ),
                // CustomActionCodeButton(
                //     code: () => widget.parameter.compiler.code,
                //     title: widget.parameter.displayName ?? '',
                //     onChanged: (value, refresh) {
                //       widget.parameter.compiler.code = value;
                //     },
                //     config: ActionCodeEditorConfig(
                //       singleLine: true,
                //       parentProcessorGiven: true,
                //     ),
                //     processor: widget.processor,
                //     onDismiss: () {
                //       widget.textEditingController.text =
                //           widget.parameter.compiler.code;
                //       checkForResult(widget.parameter.compiler.code);
                //       BlocProvider.of<ParameterBuildCubit>(context)
                //           .parameterChanged(context, widget.parameter);
                //       BlocProvider.of<ComponentCreationCubit>(context)
                //           .changedComponent();
                //     }),
                const SizedBox(
                  width: 5,
                ),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: ColorButton(
                    color: value ?? Colors.transparent,
                    onVariablePicked: (value) {
                      _operationCubit.reversibleParameterOperation(
                          widget.parameter.compiler.code, () {
                        widget.textEditingController.text =
                            widget.parameter.compiler.code = value;
                        widget.parameter.enable = true;
                        _parameterCubit.parameterChanged(widget.parameter);
                      }, (p0, component) {
                        widget.textEditingController.text =
                            widget.parameter.compiler.code = p0;
                        _parameterCubit.parameterChanged(widget.parameter,
                            component: component);
                      });
                    },
                    processor: widget.processor,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value,
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    onColorChanged: (color) {
                      _operationCubit.reversibleParameterOperation(
                          widget.parameter.compiler.code, () {
                        widget.parameter.val = color;
                        if (widget.parameter.inputCalculateAs != null) {
                          widget.parameter.val = widget
                              .parameter.inputCalculateAs!
                              .call(widget.parameter.val!, true);
                        }
                        widget.parameter.enable = true;

                        widget.textEditingController.text = widget
                            .parameter
                            .compiler
                            .code = 'Color(0x${color.value.toRadixString(16)})';
                        _parameterCubit.parameterChanged(widget.parameter);
                      }, (p0, component) {
                        widget.textEditingController.text =
                            widget.parameter.compiler.code = p0;
                        _parameterCubit.parameterChanged(widget.parameter,
                            component: component);
                      });
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
        Expanded(
          child: FVBCodeEditor(
              controller: widget.textEditingController,
              code: widget.parameter.compiler.code,
              onCodeChange: (value, refresh) {
                widget.parameter.compiler.code = value;
                widget.parameter.enable = true;
                _debounce.run(() {
                  _parameterCubit.parameterChanged(widget.parameter,
                      refresh: refresh);
                });
              },
              onErrorUpdate: (message, error) {
                final selectionCubit = context.read<SelectionCubit>();
                selectionCubit.updateError(
                    selectionCubit.selected.intendedSelection,
                    message,
                    AnalysisErrorType.parameter,
                    param: widget.parameter);
              },
              config: FVBEditorConfig(
                parentProcessorGiven: true,
                smallBottomBar: true,
                multiline: false,
                shrink: true,
              ),
              processor: widget.processor),
        )
        // SizedBox(
        //   width: 100,
        //   child: DynamicValueField<Color>(
        //     formKey: _formKey,
        //     key: _editorKey,
        //     processor: widget.processor,
        //     textEditingController: widget.textEditingController,
        //     onProcessedResult: (code, result) {
        //       widget.parameter.compiler.code = code;
        //       if (result is String) {
        //         widget.parameter.val = fromHex(result);
        //       }
        //       BlocProvider.of<ParameterBuildCubit>(context)
        //           .parameterChanged(context, widget.parameter);
        //       BlocProvider.of<ComponentCreationCubit>(context)
        //           .changedComponent();
        //       return true;
        //     },
        //   ),
        // )
      ],
    );
  }

  void checkForResult(String value) {
    FVBCacheValue? resultCache;
    try {
      resultCache = widget.parameter.process(
        value,
        processor: widget.processor,
        component: context.read<SelectionCubit>().selected.intendedSelection,
      );
    } on Exception catch (error) {
      context.read<EventLogBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage(error.toString(), ConsoleMessageType.error)));
      resultCache = null;
    }
    final result = resultCache?.value;
    widget.parameter.compiler.code = value;
    if (result is! FVBUndefined && result is String) {
      widget.parameter.val = fromHex(result);
    } else if (result == null && !widget.parameter.isRequired) {
      widget.parameter.val = null;
    }
    BlocProvider.of<ParameterBuildCubit>(context)
        .parameterChanged(widget.parameter);
  }
}

class ColorButton extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String>? onVariablePicked;
  final BoxDecoration decoration;
  final Processor? processor;

  const ColorButton(
      {Key? key,
      required this.color,
      required this.decoration,
      required this.onColorChanged,
      this.processor,
      this.onVariablePicked})
      : super(key: key);

  @override
  State<ColorButton> createState() => _ColorButtonState();
}

final List<Color> colorHistory = [];

class _ColorButtonState extends State<ColorButton> with OverlayManager {
  final AnimatedSlider _slider = AnimatedSlider();
  final key = GlobalKey();

  @override
  void dispose() {
    destroyOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // final offset=position;
        // final size=boxSize;
        if (_slider.visible) {
          _slider.hide();
        } else {
          _slider.show(
              context,
              this,
              ColorPickerUI(
                onVariablePicked: widget.onVariablePicked,
                processor: widget.processor,
                onClose: () {
                  _slider.hide();
                },
                color: widget.color,
                onColorChanged: widget.onColorChanged,
              ),
              key,
              height: 600);
        }
      },
      child: Container(
        key: key,
        decoration: widget.decoration,
        width: 30,
        height: 30,
      ),
    );
  }

  Offset get position => (key.currentContext?.findRenderObject() as RenderBox?)!
      .localToGlobal(Offset.zero);

  Size get boxSize =>
      (key.currentContext?.findRenderObject() as RenderBox?)!.size;
}

class ChoiceValueListParameterWidget extends StatelessWidget {
  final ChoiceValueListParameter parameter;

  const ChoiceValueListParameterWidget({Key? key, required this.parameter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      alignment: WrapAlignment.spaceBetween,
      children: [
        if (parameter.displayName != null &&
            (parameter.config?.labelVisible ?? true)) ...[
          Text(
            parameter.displayName!,
            style: TextStyle(
                fontSize: 15,
                color: theme.text1Color,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            width: 10,
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
                            .map((e) => MapEntry(
                                StringOperation.toNormalCase(e.toString()),
                                e.toString()))
                            .toList(),
                        getClue: parameter.getClue != null
                            ? (key, i) {
                                return parameter.getClue!
                                    .call(parameter.options[i]);
                              }
                            : null,
                        onSelection: (data) {
                          _operationCubit
                              .reversibleParameterOperation(parameter.val, () {
                            parameter.val =
                                parameter.options.indexOf(data.value);
                            _parameterCubit.parameterChanged(parameter);
                          }, (p0, component) {
                            parameter.val = p0;
                            _parameterCubit.parameterChanged(parameter,
                                component: component);
                          });
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
              child: Container(
                width: parameter.config?.width == null ? 100 : double.infinity,
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 0.5, color: theme.text3Color.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(6)),
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
                child: parameter.dynamicChild != null
                    ? parameter.dynamicChild?.call(parameter.value)
                    : Text(
                        StringOperation.toNormalCase(parameter.value),
                        style: AppFontStyle.lato(12.5,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            );
          },
        )
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
    return Container(
      margin: parameter.params.length > 1
          ? const EdgeInsets.symmetric(vertical: 2)
          : null,
      padding: parameter.params.length > 1
          ? const EdgeInsets.symmetric(vertical: 2)
          : null,
      decoration: parameter.params.length > 1
          ? BoxDecoration(
              border: Border(
              top: BorderSide(
                  color: theme.text3Color.withOpacity(0.2), width: 0.5),
              bottom: BorderSide(
                  color: theme.text3Color.withOpacity(0.2), width: 0.5),
            ))
          : null,
      child: StatefulBuilder(builder: (context, setState) {
        return Column(
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
                            _operationCubit.reversibleParameterOperation(
                                parameter.enable, () {
                              parameter.enable = tick;
                              setState(() {});
                              _parameterCubit.parameterChanged(parameter);
                            }, (p0, component) {
                              parameter.enable = p0;
                              _parameterCubit.parameterChanged(parameter,
                                  component: component);
                            });
                          }
                        },
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                  Text(
                    parameter.displayName!,
                    style: AppFontStyle.lato(14,
                        color: theme.text1Color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 5,
            ),
            if (parameter.enable)
              Wrap(
                spacing: 0,
                runSpacing: 5,
                children: [
                  for (final subParam in parameter.params) ...[
                    ParameterWidget(
                      parameter: subParam,
                    ),
                  ]
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
  late Processor processor;

  final Debounce _debounce =
      Debounce(const Duration(milliseconds: debounceTimeInMillis));

  @override
  void initState() {
    super.initState();
    _textEditingController.text = widget.parameter.compiler.code;
  }

  @override
  void didChangeDependencies() {
    processor = ProcessorProvider.maybeOf(context)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (widget.parameter.config?.labelVisible ?? true) ...[
          Text(
            widget.parameter.displayName!,
            style: AppFontStyle.lato(13,
                color: theme.text1Color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            width: 5,
          ),
        ] else if (widget.parameter.config?.icon != null) ...[
          Icon(
            widget.parameter.config!.icon!,
            size: 20,
          ),
          const SizedBox(
            width: 5,
          )
        ],
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<ParameterBuildCubit, ParameterBuildState>(
                  builder: (_, state) {
                final value = widget.parameter.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: value != null
                      ? AppSwitch(
                          value: value,
                          onToggle: (bool value) {
                            _operationCubit.reversibleParameterOperation(
                                widget.parameter.compiler.code, () {
                              widget.parameter.compiler.code =
                                  _textEditingController.text =
                                      value.toString();
                              setState(() {});
                              _parameterCubit
                                  .parameterChanged(widget.parameter);
                            }, (p0, component) {
                              widget.parameter.compiler.code =
                                  _textEditingController.text = p0;
                              setState(() {});
                              _parameterCubit.parameterChanged(widget.parameter,
                                  component: component);
                            });
                          },
                        )
                      : const Offstage(),
                );
              }),
              // CustomActionCodeButton(
              //     code: () => widget.parameter.compiler.code,
              //     title: widget.parameter.displayName ?? '',
              //     onChanged: (value, refresh) {
              //       widget.parameter.compiler.code = value;
              //     },
              //     config: ActionCodeEditorConfig(
              //       singleLine: true,
              //       parentProcessorGiven: true,
              //     ),
              //     processor: processor,
              //     onDismiss: () {
              //       checkForResult(widget.parameter.compiler.code);
              //       setState(() {});
              //     }),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: SizedBox(
                  width: Responsive.isMobile(context) ? 120 : 200,
                  child: FVBCodeEditor(
                      controller: _textEditingController,
                      code: widget.parameter.compiler.code,
                      onCodeChange: (value, refresh) {
                        _debounce.run(() {
                          widget.parameter.compiler.code = value;
                          _parameterCubit.parameterChanged(widget.parameter,
                              refresh: refresh);
                        });
                      },
                      onErrorUpdate: (message, error) {
                        final selectionCubit = context.read<SelectionCubit>();
                        selectionCubit.updateError(
                            selectionCubit.selected.intendedSelection,
                            message,
                            AnalysisErrorType.parameter,
                            param: widget.parameter);
                      },
                      config: FVBEditorConfig(
                        parentProcessorGiven: true,
                        smallBottomBar: true,
                        multiline: false,
                        shrink: true,
                        string: false,
                      ),
                      processor: processor),
                ),
              )
              // SizedBox(
              //   width: 150,
              //   child: DynamicValueField<bool>(
              //       formKey: _formKey,
              //       processor: processor,
              //       onProcessedResult: (code, value) {
              //         widget.parameter.compiler.code = code;
              //         if (value is! FVBUndefined) {
              //           if (value != null || !widget.parameter.isRequired) {
              //             widget.parameter.val = value;
              //             BlocProvider.of<ParameterBuildCubit>(context)
              //                 .parameterChanged(context, widget.parameter);
              //             BlocProvider.of<ComponentCreationCubit>(context)
              //                 .changedComponent();
              //           }
              //         }
              //         return true;
              //       },
              //       textEditingController: _textEditingController),
              // ),
            ],
          ),
        )
      ],
    );
  }

  void checkForResult(String value) {
    dynamic result;
    try {
      result = widget.parameter.process(
        value,
        processor: processor,
        component: context.read<SelectionCubit>().selected.intendedSelection,
      );
    } on Exception catch (error) {
      context.read<EventLogBloc>().add(ConsoleUpdatedEvent(
          ConsoleMessage(error.toString(), ConsoleMessageType.error)));
      result = null;
    }
    widget.parameter.compiler.code = value;
    if (result is! FVBUndefined && result is bool) {
      widget.parameter.val = result;
    } else if (result == null && !widget.parameter.isRequired) {
      widget.parameter.val = null;
    }
    _parameterCubit.parameterChanged(widget.parameter);
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
class Debounce {
  final Duration duration;
  Timer? timer;

  Debounce(this.duration);

  void run(VoidCallback callback) {
    if (timer != null) {
      timer?.cancel();
    }
    timer = Timer(duration, callback);
  }
}
