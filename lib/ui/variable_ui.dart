import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/datatype_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_classes.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';
import 'package:get/get.dart';

import '../collections/project_info_collection.dart';
import '../common/common_methods.dart';
import '../common/converter/string_operation.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/extension_util.dart';
import '../common/validations.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../injector.dart';
import '../models/variable_model.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/color_picker.dart';
import '../widgets/textfield/app_textfield.dart';
import '../widgets/textfield/appt_search_field.dart';
import 'common/variable_dialog.dart';
import 'navigation/animated_slider.dart';
import 'parameter_ui.dart';

class VariableBox extends StatefulWidget {
  final void Function(FVBVariable) onAdded;
  final void Function(FVBVariable) onChanged;
  final void Function(FVBVariable) onDeleted;
  final OperationCubit componentOperationCubit;
  final CreationCubit componentCreationCubit;
  final SelectionCubit componentSelectionCubit;
  final String title;
  final Map<String, FVBVariable> variables;
  final List<VariableDialogOption> options;

  const VariableBox(
      {Key? key,
      required this.componentOperationCubit,
      required this.componentCreationCubit,
      required this.componentSelectionCubit,
      required this.title,
      required this.onAdded,
      required this.onChanged,
      required this.variables,
      required this.onDeleted,
      this.options = const []})
      : super(key: key);

  @override
  _VariableBoxState createState() => _VariableBoxState();
}

class _VariableBoxState extends State<VariableBox> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final UserProjectCollection _collection = sl<UserProjectCollection>();

  @override
  Widget build(BuildContext context) {
    final variables = widget.variables.entries.toList(growable: false);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2)
          ]),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Row(
                children: [
                  Text(
                    'Variables',
                    style: AppFontStyle.headerStyle(),
                  ),
                  10.wBox,
                  Text(
                    widget.title,
                    style: AppFontStyle.lato(
                      14,
                      color: ColorAssets.darkerGrey.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )),
              10.wBox,
              AppCloseButton(
                onTap: () {
                  AnimatedSliderProvider.of(context)?.hide();
                },
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          AddVariableWidget(
            onAdded: (_) {
              widget.onAdded.call(_);
              setState(() {});
            },
            processor: _collection.project!.processor,
          ),
          const Divider(
            height: 20,
          ),
          SizedBox(
            height: 35,
            width: 240,
            child: AppSearchField(
              hint: 'Search variables...',
              controller: _searchController,
            ),
          ),
          10.hBox,
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: ListenableBuilder(
                listenable: _searchController,
                builder: (context, _) {
                  final search = _searchController.text.toLowerCase();
                  final filtered = variables
                      .where((element) =>
                          element.key.toLowerCase().contains(search))
                      .toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    separatorBuilder: (_, __) {
                      return const SizedBox(
                        height: 4,
                      );
                    },
                    controller: _scrollController,
                    itemBuilder: (context, i) {
                      return EditVariable(
                        filtered[i].value,
                        onChanged: widget.onChanged,
                        onDelete: (model) {
                          widget.onDeleted.call(model);
                          setState(() {});
                        },
                        setState2: setState,
                        options: widget.options,
                      );
                    },
                    itemCount: filtered.length,
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class AddVariableWidget extends StatefulWidget {
  final void Function(VariableModel) onAdded;
  final Processor processor;
  final TextEditingController? controller;
  final dynamic value;

  const AddVariableWidget({
    Key? key,
    this.value,
    required this.onAdded,
    required this.processor,
    this.controller,
  }) : super(key: key);

  @override
  State<AddVariableWidget> createState() => _AddVariableWidgetState();
}

class _AddVariableWidgetState extends State<AddVariableWidget> {
  final TextEditingController _controller1 = TextEditingController(),
      _controller2 = TextEditingController();
  static final List<DataType> possibleTypes = [
    DataType.fvbInt,
    DataType.string,
    DataType.fvbDouble,
    DataType.fvbBool,
    fvbColor,
    DataType.fvbDynamic,
  ];
  DataType dataType = DataType.fvbDouble;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      dataType = DataTypeProcessor.getDartTypeToDatatype(widget.value);
      if (possibleTypes.firstWhereOrNull((e) => e.equals(dataType)) == null) {
        dataType = DataType.fvbDynamic;
      }
      _controller2.text = widget.value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(
            widthFactor: 0.7,
            child: AppTextField(
              controller: _controller1,
              hintText: 'Name',
              validator: Validations.commonNameValidator(),
              height: 35,
            ),
          ),
          8.hBox,
          Row(
            children: [
              SizedBox(
                width: 120,
                child: CustomDropdownButton<DataType>(
                  style: AppFontStyle.lato(14),
                  value: dataType,
                  hint: null,
                  items: possibleTypes
                      .map<CustomDropdownMenuItem<DataType>>(
                        (e) => CustomDropdownMenuItem<DataType>(
                          value: e,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              StringOperation.capitalize(e.fvbName ?? e.name),
                              style: AppFontStyle.lato(14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      dataType = value;
                    });
                  },
                  selectedItemBuilder: (context, e) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        StringOperation.capitalize(e.fvbName ?? e.name),
                        style:
                            AppFontStyle.lato(14, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              if (dataType.equals(fvbColor)) ...[
                Builder(builder: (context) {
                  final value = widget.processor
                      .process(
                        _controller2.text,
                        config: const ProcessorConfig(unmodifiable: true),
                      )
                      .value;
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if (value is! FVBInstance ||
                        (value).fvbClass.name != 'Color') {
                      _controller2.text = 'Colors.black';
                    }
                  });
                  return ColorPicker(
                      color: value is FVBInstance ? value.toDart() : null,
                      onChange: (color) {
                        _controller2.text =
                            'Color(0x${color.value.toRadixString(16)})';
                      });
                }),
                const SizedBox(
                  width: 5,
                ),
              ],
              Expanded(
                child: AppTextField(
                  controller: _controller2,
                  hintText: 'Value',
                  height: 35,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              InkWell(
                onTap: () {
                  if (_controller1.text.isEmpty) {
                    showToast('Please enter variable name and it\'s value',
                        error: true);
                    return;
                  }
                  final name = _controller1.text;
                  final capitalACode = 'A'.codeUnits[0],
                      smallZCode = 'z'.codeUnits[0];
                  final intStart = '0'.codeUnits[0], intEnd = '9'.codeUnits[0];
                  for (final codeUnit in name.codeUnits) {
                    if ((codeUnit < capitalACode || codeUnit > smallZCode) &&
                        (codeUnit < intStart || codeUnit > intEnd)) {
                      showToast('Only characters are allowed in variable name',
                          error: true);
                      return;
                    }
                  }

                  final variables = widget.processor.variables.keys;
                  for (final variable in variables) {
                    if (variable == name) {
                      showToast('Variable already exist, Choose different name',
                          error: true);
                      return;
                    }
                  }
                  Processor.error = false;
                  final valueCache = widget.processor.process(
                      dataType.equals(DataType.string)
                          ? '"${_controller2.text}"'
                          : _controller2.text,
                      config: const ProcessorConfig(unmodifiable: true));
                  final value = valueCache.value;
                  if (value != null ||
                      DataTypeProcessor.checkIfValidDataTypeOfValue(
                          widget.processor, value, dataType, name, false)) {
                    widget.onAdded.call(VariableModel(name, dataType,
                        value: value, uiAttached: true));

                    _controller1.text = '';
                    _controller2.text = '';

                    setState(() {});
                  } else
                    showToast('Invalid Value', error: true);
                },
                borderRadius: BorderRadius.circular(6),
                child: const Icon(
                  Icons.done,
                  color: Colors.blueAccent,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class EditVariable extends StatefulWidget {
  final FVBVariable variable;

  final void Function(FVBVariable) onChanged;
  final void Function(FVBVariable)? onDelete;
  final List<VariableDialogOption> options;
  final TextEditingController? controller;
  final StateSetter setState2;
  final bool? editable;
  final bool? deletable;

  const EditVariable(this.variable,
      {Key? key,
      required this.onChanged,
      required this.setState2,
      this.onDelete,
      required this.options,
      this.controller,
      this.editable,
      this.deletable})
      : super(key: key);

  @override
  _EditVariableState createState() => _EditVariableState();
}

class _EditVariableState extends State<EditVariable> {
  late TextEditingController _textEditingController;
  final Debounce _debounce = Debounce(const Duration(milliseconds: 200));
  final UserProjectCollection _collection = sl<UserProjectCollection>();

  @override
  void initState() {
    super.initState();
    _textEditingController = widget.controller ??
        TextEditingController.fromValue(
          TextEditingValue(text: '${widget.variable.value}'),
        );
  }

  @override
  Widget build(BuildContext context) {
    final variable = widget.variable;
    final editable = widget.editable ??
        (!variable.isFinal &&
            (variable is VariableModel && variable.uiAttached) &&
            ([
              DataType.fvbInt,
              DataType.fvbDouble,
              DataType.string,
              DataType.fvbBool,
              DataType.fvbDynamic,
              fvbColor
            ].contains(variable.dataType)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              IntrinsicWidth(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: widget.variable.name));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.variable.name,
                                style: AppFontStyle.lato(
                                  13,
                                  color: widget.variable.isFinal
                                      ? Colors.black
                                      : ColorAssets.theme,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Icon(
                          Icons.copy,
                          size: 18,
                          color: ColorAssets.grey,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              if (widget.variable.dataType.equals(fvbColor)) ...[
                ColorPicker(
                    color: widget.variable.value is FVBInstance
                        ? (widget.variable.value as FVBInstance?)?.toDart()
                        : null,
                    onChange: (color) {
                      setState(() {
                        widget.variable.value = FVBModuleClasses.fvbColorClass
                            .createInstance(
                                OperationCubit.paramProcessor, [color.value]);
                        _textEditingController.text =
                            widget.variable.value.toString();
                        widget.onChanged.call(widget.variable);
                      });
                    }),
                const SizedBox(
                  width: 5,
                ),
              ],
              Expanded(
                child: AppTextField(
                  enabled: editable,
                  height: 35,
                  controller: _textEditingController,
                  onChanged: (val) {
                    _debounce.run(() {
                      final valueCache = _collection.project!.processor.process(
                          widget.variable.dataType.equals(DataType.string)
                              ? '"${_textEditingController.text}"'
                              : _textEditingController.text,
                          config: const ProcessorConfig(unmodifiable: true));
                      final value = valueCache.value;
                      if (!Processor.error &&
                          value != null &&
                          DataTypeProcessor.checkIfValidDataTypeOfValue(
                              _collection.project!.processor,
                              value,
                              variable.dataType,
                              variable.name,
                              false)) {
                        widget.variable
                            .setValue(_collection.project!.processor, value);
                        widget.onChanged.call(widget.variable);
                        setState(() {});
                      }
                    });
                  },
                ),
              ),
              CustomPopupMenuButton(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: theme.text1Color,
                  ),
                ),
                itemBuilder: (BuildContext context) => [
                  if (widget.onDelete != null &&
                      (widget.deletable ??
                          (variable is VariableModel &&
                              variable.uiAttached &&
                              variable.deletable)))
                    const CustomPopupMenuItem(
                      value: 0,
                      child: Text('Delete'),
                    ),
                  ...widget.options.map((option) {
                    return CustomPopupMenuItem<VariableDialogOption>(
                      value: option,
                      child: Text(
                        option.name,
                      ),
                    );
                  })
                ],
                onSelected: (i) {
                  switch (i) {
                    case 0:
                      widget.onDelete?.call(variable);
                      setState(() {});
                      break;
                    case (VariableDialogOption option):
                      option.callback.call(widget.variable as VariableModel);
                      widget.setState2(() {});
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Text(
                widget.variable.dataType.fvbName ??
                    widget.variable.dataType.name,
                style: AppFontStyle.lato(
                  13,
                  color: theme.text2Color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.variable.value is String ||
                  widget.variable.value is int ||
                  widget.variable.value is bool ||
                  widget.variable.value is double)
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Value',
                        style:
                            AppFontStyle.lato(12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: SelectableText(
                          widget.variable.value.toString(),
                          style: AppFontStyle.lato(
                            12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if ((variable is VariableModel && variable.description != null))
          Container(
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
                color: ColorAssets.lightGrey,
                borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.all(4.0),
            child: Text(
              variable.description!,
              style: AppFontStyle.lato(13,
                  color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
