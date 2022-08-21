import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../common/common_methods.dart';
import '../common/compiler/code_processor.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/custom_text_field.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/variable_model.dart';

import 'common/variable_dialog.dart';
import 'project_selection_page.dart';

class VariableBox extends StatefulWidget {
  final void Function(VariableModel) onAdded;
  final void Function(VariableModel) onChanged;
  final void Function(VariableModel) onDeleted;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final OverlayEntry overlayEntry;
  final String title;
  final Map<String, FVBVariable> variables;
  final List<VariableDialogOption> options;

  const VariableBox(
      {Key? key,
      required this.overlayEntry,
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
  final TextEditingController _controller1 = TextEditingController(),
      _controller2 = TextEditingController();
  DataType dataType = DataType.fvbDouble;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final variables = widget.variables.entries.toList(growable: false);
    return Card(
      elevation: 5,
      color: Colors.white,
      child: Container(
        height: dh(context, 100) - 70,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppFontStyle.roboto(15, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    widget.overlayEntry.remove();
                  },
                  child: const Icon(
                    Icons.close,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller1,
                      style:
                          AppFontStyle.roboto(13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        'type',
                        style: AppFontStyle.roboto(13,
                            color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomDropdownButton<DataType>(
                      style: AppFontStyle.roboto(14),
                      value: dataType,
                      hint: null,
                      items: [
                        DataType.fvbInt,
                        DataType.string,
                        DataType.fvbDouble,
                        DataType.fvbBool
                      ]
                          .map<CustomDropdownMenuItem<DataType>>(
                            (e) => CustomDropdownMenuItem<DataType>(
                              value: e,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  e.name,
                                  style: AppFontStyle.roboto(14,
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
                            e.name,
                            style: AppFontStyle.roboto(14,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        ' = ',
                        style: AppFontStyle.roboto(15,
                            color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller2,
                      style:
                          AppFontStyle.roboto(13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  IconButton(
                    onPressed: () {
                      if (_controller1.text.isEmpty) {
                        showToast('Please enter variable name and it\'s value',
                            error: true);
                        return;
                      }
                      final name = _controller1.text;
                      final capitalACode = 'A'.codeUnits[0],
                          smallZCode = 'z'.codeUnits[0];
                      final intStart = '0'.codeUnits[0],
                          intEnd = '9'.codeUnits[0];
                      for (final codeUnit in name.codeUnits) {
                        if ((codeUnit < capitalACode ||
                                codeUnit > smallZCode) &&
                            (codeUnit < intStart || codeUnit > intEnd)) {
                          showToast(
                              'Only characters are allowed in variable name',
                              error: true);
                          return;
                        }
                      }

                      final variables =
                          ComponentOperationCubit.processor.variables.keys;
                      for (final variable in variables) {
                        if (variable == name) {
                          showToast(
                              'Variable already exist, Choose different name',
                              error: true);
                          return;
                        }
                      }
                      late final dynamic value;
                      switch (dataType) {
                        case DataType.fvbInt:
                          value = int.tryParse(_controller2.text);
                          break;
                        case DataType.fvbDouble:
                          value = double.tryParse(_controller2.text);
                          break;
                        case DataType.string:
                          value = _controller2.text;
                          break;
                        case DataType.fvbBool:
                          value = _controller2.text == 'true';
                          break;
                        case DataType.dynamic:
                          if (double.tryParse(_controller2.text) != null) {
                            value = double.tryParse(_controller2.text);
                          } else if (int.tryParse(_controller2.text) != null) {
                            value = int.tryParse(_controller2.text);
                          } else if (_controller2.text == 'true' ||
                              _controller2.text == 'false') {
                            value = _controller2.text == 'true';
                          } else {
                            value = _controller2.text;
                          }
                          break;
                        case DataType.fvbFunction:
                          break;
                        case DataType.unknown:
                          break;
                      }
                      if (value == null) {
                        showToast('Please enter valid value', error: true);
                        return;
                      }
                      widget.onAdded.call(VariableModel(name, dataType,
                          value: value, uiAttached: true));

                      _controller1.text = '';
                      _controller2.text = '';

                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.blueAccent,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemBuilder: (context, i) {
                  return EditVariable(
                    variables[i],
                    widget.componentCreationCubit,
                    widget.componentSelectionCubit,
                    widget.componentOperationCubit,
                    onChanged: widget.onChanged,
                    onDelete: (model) {
                      widget.onDeleted.call(model);
                      setState(() {});
                    },
                    setState2: setState,
                    options: widget.options,
                  );
                },
                itemCount: variables.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditVariable extends StatefulWidget {
  final MapEntry<String, FVBVariable> variable;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;
  final void Function(VariableModel) onChanged;
  final void Function(VariableModel) onDelete;
  final List<VariableDialogOption> options;

  final StateSetter setState2;

  const EditVariable(this.variable, this.componentCreationCubit,
      this.componentSelectionCubit, this.componentOperationCubit,
      {Key? key,
      required this.onChanged,
      required this.setState2,
      required this.onDelete,
      required this.options})
      : super(key: key);

  @override
  _EditVariableState createState() => _EditVariableState();
}

class _EditVariableState extends State<EditVariable> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController.fromValue(
      TextEditingValue(text: '${widget.variable.value.value}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variable = widget.variable.value;
    return Row(
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.variable.key));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        widget.variable.key,
                        style: AppFontStyle.roboto(
                          15,
                          color: widget.variable.value.isFinal
                              ? Colors.black
                              : AppColors.theme,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Icon(
                      Icons.copy,
                      size: 18,
                      color: AppColors.grey,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              ' = ',
              style: AppFontStyle.roboto(15,
                  color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: CustomTextField(
            enabled: !variable.isFinal &&
                (variable is VariableModel && variable.uiAttached) &&
                ([
                  DataType.fvbInt,
                  DataType.fvbDouble,
                  DataType.string,
                  DataType.fvbBool
                ].contains(variable.dataType)),
            controller: _textEditingController,
            onChange: (val) {
              late final dynamic value;
              switch (widget.variable.value.dataType) {
                case DataType.fvbInt:
                  value = int.tryParse(val);
                  break;
                case DataType.fvbDouble:
                  value = double.tryParse(val);
                  break;
                case DataType.string:
                  value = val;
                  break;
                case DataType.fvbBool:
                  value = val == 'true';
                  break;
                case DataType.dynamic:
                  if (double.tryParse(val) != null) {
                    value = double.tryParse(val);
                  } else if (int.tryParse(val) != null) {
                    value = int.tryParse(val);
                  } else if (val == 'true' || val == 'false') {
                    value = val == 'true';
                  } else {
                    value = val;
                  }
                  break;
              }
              if (value != null) {
                widget.variable.value.value = value;
                widget.onChanged.call(widget.variable.value as VariableModel);
              }
            },
          ),
        ),
        if (widget.options.isNotEmpty)
          CustomPopupMenuButton<VariableDialogOption>(
            child: const Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
            onSelected: (val) {
              val.callback.call(widget.variable.value as VariableModel);
              widget.setState2(() {});
            },
            itemBuilder: (context) {
              return widget.options.map((option) {
                return CustomPopupMenuItem<VariableDialogOption>(
                  value: option,
                  child: Text(
                    option.name,
                  ),
                );
              }).toList();
            },
          ),
        if ((variable is VariableModel && variable.description != null))
          Container(
            width: 200,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              variable.description!,
              style: AppFontStyle.roboto(12,
                  color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
        if (variable is VariableModel &&
            variable.uiAttached &&
            variable.deletable) ...[
          const SizedBox(
            width: 20,
          ),
          AppIconButton(
            onPressed: () {
              widget.onDelete.call(variable);
              setState(() {});
            },
            icon: Icons.delete,
            color: Colors.red,
          )
        ]
      ],
    );
  }
}
