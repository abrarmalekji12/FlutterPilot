import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/constant/app_colors.dart';
import 'package:flutter_builder/constant/font_style.dart';
import 'package:flutter_builder/cubit/component_creation/component_creation_cubit.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/parameter_build_cubit/parameter_build_cubit.dart';
import 'package:flutter_builder/firestore/firestore_bridge.dart';
import 'package:flutter_builder/models/variable_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VariableBox extends StatefulWidget {
  const VariableBox({Key? key}) : super(key: key);

  @override
  _VariableBoxState createState() => _VariableBoxState();
}

class _VariableBoxState extends State<VariableBox> {
  final TextEditingController _controller1 = TextEditingController(),
      _controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final variables = ComponentOperationCubit.codeProcessor.variables.entries
          .toList(growable: false);
      return Card(
        elevation: 5,
        color: Colors.white,
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                          ' = ',
                          style: AppFontStyle.roboto(15,
                              color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller2,
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
                        final value = double.tryParse(_controller2.text);
                        if (value == null) {
                          Fluttertoast.showToast(
                              msg: 'Please enter valid value',
                              toastLength: Toast.LENGTH_LONG,
                              timeInSecForIosWeb: 3);
                          return;
                        }
                        final name = _controller1.text;
                        final capitalACode = 'A'.codeUnits[0],
                            smallZCode = 'z'.codeUnits[0];
                        for (final codeUnit in name.codeUnits) {
                          if (codeUnit < capitalACode ||
                              codeUnit > smallZCode) {
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
                        ComponentOperationCubit.codeProcessor.variables[name] =
                            VariableModel(name, value, false, null);
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
                              onChanged: (value) {
                                final num = double.tryParse(value);
                                if (num != null) {
                                  ComponentOperationCubit.codeProcessor
                                      .variables[variables[i].key]!.value = num;
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
                                    color: Colors.black,fontWeight: FontWeight.w600),
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
