import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:fluttertoast/fluttertoast.dart';

import 'models_view.dart';

class VariableBox extends StatefulWidget {
  final void Function(VariableModel) onAdded;
  final void Function(VariableModel) onChanged;
  final void Function(VariableModel) onDeleted;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentCreationCubit componentCreationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final OverlayEntry overlayEntry;
  final String title;
  final Map<String,VariableModel> variables;

  const VariableBox(
      {Key? key,
      required this.overlayEntry,
      required this.componentOperationCubit,
      required this.componentCreationCubit,
      required this.componentSelectionCubit,
      required this.title,
      required this.onAdded,
      required this.onChanged, required this.variables, required this.onDeleted})
      : super(key: key);

  @override
  _VariableBoxState createState() => _VariableBoxState();
}

class _VariableBoxState extends State<VariableBox> {
  final TextEditingController _controller1 = TextEditingController(),
      _controller2 = TextEditingController();
  DataType dataType = DataType.double;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final variables = widget.variables.entries
        .toList(growable: false);
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
                      items: DataType.values
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
                        Fluttertoast.showToast(
                            msg: 'Please enter variable name and it\'s value',
                            toastLength: Toast.LENGTH_LONG,
                            timeInSecForIosWeb: 3);
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
                          Fluttertoast.showToast(
                              msg:
                                  'Only characters are allowed in variable name',
                              toastLength: Toast.LENGTH_LONG,
                              timeInSecForIosWeb: 3);
                          return;
                        }
                      }

                      final variables =
                          ComponentOperationCubit.codeProcessor.variables.keys;
                      for (final variable in variables) {
                        if (variable == name) {
                          Fluttertoast.showToast(
                              msg:
                                  'Variable already exist, Choose different name',
                              toastLength: Toast.LENGTH_LONG,
                              timeInSecForIosWeb: 3);
                          return;
                        }
                      }
                      late final dynamic value;
                      switch (dataType) {
                        case DataType.int:
                          value = int.tryParse(_controller2.text);
                          break;
                        case DataType.double:
                          value = double.tryParse(_controller2.text);
                          break;
                        case DataType.string:
                          value = _controller2.text;
                          break;
                        case DataType.bool:
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
                        case DataType.list:
                          break;
                        case DataType.iterable:
                          break;
                        case DataType.map:
                          break;
                        case DataType.fvbInstance:
                          break;
                        case DataType.fvbFunction:
                          break;
                        case DataType.unknown:
                          break;
                      }
                      if (value == null) {
                        Fluttertoast.showToast(
                            msg: 'Please enter valid value',
                            toastLength: Toast.LENGTH_LONG,
                            timeInSecForIosWeb: 3);
                        return;
                      }
                      widget.onAdded.call(VariableModel(
                        name,
                        value,
                        false,
                        null,
                        dataType,
                        widget.title,uiAttached: true
                      ));

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
                    onDelete: widget.onDeleted,
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
  final MapEntry<String, VariableModel> variable;
  final ComponentOperationCubit componentOperationCubit;
  final ComponentSelectionCubit componentSelectionCubit;
  final ComponentCreationCubit componentCreationCubit;
  final void Function(VariableModel) onChanged;
  final void Function(VariableModel) onDelete;
  const EditVariable(this.variable, this.componentCreationCubit,
      this.componentSelectionCubit, this.componentOperationCubit,
      {Key? key, required this.onChanged,required this.onDelete})
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
    return Row(
      children: [
        Expanded(
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
                          color: widget.variable.value.runtimeAssigned
                              ? Colors.black
                              : AppColors.theme,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10,),
                    const Icon(Icons.copy,size: 18,color: AppColors.grey,)
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
        if (!widget.variable.value.runtimeAssigned &&
            ([DataType.int, DataType.double, DataType.string, DataType.bool]
                .contains(widget.variable.value.dataType)))
          Expanded(
            child: CustomTextField(
              controller: _textEditingController,
              onChange: (val) {
                late final dynamic value;
                switch (widget.variable.value.dataType) {
                  case DataType.int:
                    value = int.tryParse(val);
                    break;
                  case DataType.double:
                    value = double.tryParse(val);
                    break;
                  case DataType.string:
                    value = val;
                    break;
                  case DataType.bool:
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
                  case DataType.list:
                    break;
                  case DataType.iterable:
                    break;
                  case DataType.map:
                    break;
                  case DataType.fvbInstance:
                    break;
                  case DataType.fvbFunction:
                    break;
                  case DataType.unknown:
                    // TODO: Handle this case.
                    break;
                }
                if (value != null) {
                  widget.variable.value.value = value;
                  widget.onChanged.call(widget.variable.value);
                }
              },
            ),
          ),
        if (widget.variable.value.description != null)
          Expanded(
            child: Center(
              child: Text(
                widget.variable.value.description!,
                style: AppFontStyle.roboto(12,
                    color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (widget.variable.value.deletable) ...[
          const SizedBox(
            width: 20,
          ),
          IconButton(
            onPressed: () {
              widget.onDelete.call(widget.variable.value);
             setState(() {});
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          )
        ]
      ],
    );
  }
}
