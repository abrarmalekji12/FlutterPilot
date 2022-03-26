import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../models/variable_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'models_view.dart';

class VariableBox extends StatefulWidget {
  const VariableBox({Key? key}) : super(key: key);

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
    return Builder(builder: (context) {
      final variables = ComponentOperationCubit.codeProcessor.variables.entries
          .toList(growable: false);
      return Card(
        elevation: 5,
        color: Colors.white,
        child: Container(
          height: dh(context, 100) - 70,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Variables',
                style: AppFontStyle.roboto(15, fontWeight: FontWeight.bold),
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
                        style: AppFontStyle.roboto(13,fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1),
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

                        style: AppFontStyle.roboto(13,fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        if (_controller1.text.isEmpty ||
                            _controller2.text.isEmpty) {
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

                        final variables = ComponentOperationCubit
                            .codeProcessor.variables.keys;
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
                        }
                        if (value == null) {
                          Fluttertoast.showToast(
                              msg: 'Please enter valid value',
                              toastLength: Toast.LENGTH_LONG,
                              timeInSecForIosWeb: 3);
                          return;
                        }
                        ComponentOperationCubit.codeProcessor.variables[name] =
                            VariableModel(
                          name,
                          value,
                          false,
                          null,
                          dataType,
                          BlocProvider.of<ComponentOperationCubit>(context,
                                  listen: false)
                              .flutterProject!
                              .currentScreen
                              .name,
                        );
                        _controller1.text = '';
                        _controller2.text = '';
                        BlocProvider.of<ComponentOperationCubit>(context,
                                listen: false)
                            .addVariable(ComponentOperationCubit
                                .codeProcessor.variables[name]!);
                        BlocProvider.of<ComponentCreationCubit>(context,
                                listen: false)
                            .changedComponent();
                        BlocProvider.of<ComponentSelectionCubit>(context,
                                listen: false)
                            .emit(ComponentSelectionChange());
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
                    return Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              variables[i].key,
                              style: AppFontStyle.roboto(
                                15,
                                color: variables[i].value.runtimeAssigned
                                    ? Colors.black
                                    : AppColors.theme,
                                fontWeight: FontWeight.w500,
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
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        if (!variables[i].value.runtimeAssigned)
                          Expanded(
                            child: TextField(
                              controller: TextEditingController.fromValue(
                                  TextEditingValue(
                                      text: '${variables[i].value.value}')),
                              onChanged: (val) {
                                late final dynamic value;
                                switch (variables[i].value.dataType) {
                                  case DataType.int:
                                    value = int.tryParse(val);
                                    break;
                                  case DataType.double:
                                    value = double.tryParse(val);
                                    break;
                                  case DataType.string:
                                    value = val;
                                    break;
                                }
                                if (value != null) {
                                  ComponentOperationCubit
                                      .codeProcessor
                                      .variables[variables[i].key]!
                                      .value = value;
                                  Future.delayed(
                                      const Duration(milliseconds: 500), () {
                                    BlocProvider.of<ComponentOperationCubit>(
                                            context,
                                            listen: false)
                                        .updateVariable(ComponentOperationCubit
                                            .codeProcessor
                                            .variables[variables[i].key]!);
                                    BlocProvider.of<ComponentCreationCubit>(
                                            context,
                                            listen: false)
                                        .changedComponent();
                                    BlocProvider.of<ComponentSelectionCubit>(
                                            context,
                                            listen: false)
                                        .emit(ComponentSelectionChange());
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(5),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                            ),
                          ),
                        if (variables[i].value.description != null)
                          Expanded(
                            child: Center(
                              child: Text(
                                variables[i].value.description!,
                                style: AppFontStyle.roboto(12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        if (variables[i].value.deletable) ...[
                          const SizedBox(
                            width: 20,
                          ),
                          IconButton(
                            onPressed: () {
                              ComponentOperationCubit.codeProcessor.variables
                                  .remove(variables[i].key);
                              BlocProvider.of<ComponentCreationCubit>(context,
                                      listen: false)
                                  .changedComponent();
                              BlocProvider.of<ComponentSelectionCubit>(context,
                                      listen: false)
                                  .emit(ComponentSelectionChange());
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
                  },
                  itemCount: variables.length,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
