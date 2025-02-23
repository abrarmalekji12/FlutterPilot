import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project/project_selection_page.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_function_variables.dart';

import '../code_operations.dart';
import '../collections/project_info_collection.dart';
import '../common/app_button.dart';
import '../common/common_methods.dart';
import '../common/converter/string_operation.dart';
import '../common/custom_drop_down.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/editable_textview.dart';
import '../common/extension_util.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/model/model_cubit.dart';
import '../cubit/user_details/user_details_cubit.dart';
import '../injector.dart';
import '../models/local_model.dart';
import '../models/variable_model.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/empty_text.dart';
import '../widgets/textfield/app_textfield.dart';
import 'navigation/animated_dialog.dart';
import 'navigation/animated_slider.dart';
import 'parameter_ui.dart';
import 'variable_ui.dart';

class ModelBox extends StatefulWidget {
  const ModelBox({
    Key? key,
  }) : super(key: key);

  @override
  _ModelBoxState createState() => _ModelBoxState();
}

final UserProjectCollection _collection = sl<UserProjectCollection>();

class _ModelBoxState extends State<ModelBox> {
  late final ModelCubit _modelCubit;
  late final OperationCubit componentOperationCubit;
  late final CreationCubit componentCreationCubit;
  late final SelectionCubit componentSelectionCubit;

  @override
  void initState() {
    super.initState();
    componentOperationCubit = context.read<OperationCubit>();
    componentCreationCubit = context.read<CreationCubit>();
    componentSelectionCubit = context.read<SelectionCubit>();

    _modelCubit = ModelCubit(componentOperationCubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDetailsCubit, UserDetailsState>(
      buildWhen: (state1, state2) => state2 is FlutterProjectLoadedState,
      builder: (context, state) {
        return FocusScope(
          child: Container(
            width: 400,
            height: dh(context, 80),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2)
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: BlocProvider<ModelCubit>(
              create: (context) => _modelCubit,
              child: BlocConsumer<ModelCubit, ModelState>(
                bloc: _modelCubit,
                listener: (context, state) {
                  if (state is ModelChangedState) {}
                },
                builder: (context, state) {
                  final list =
                      Processor.classes.values.whereType<FVBModelClass>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Models',
                            style: AppFontStyle.titleStyle(),
                          ),
                          AppCloseButton(
                            onTap: () {
                              AnimatedSliderProvider.of(context)?.hide();
                            },
                          )
                        ],
                      ),
                      10.hBox,
                      const AddModelTile(),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                          child: SingleChildScrollView(
                        child: SelectionArea(
                          child: Column(
                            children: [
                              if (list.isEmpty)
                                const EmptyTextWidget(
                                  text: 'No models',
                                )
                              else
                                Column(
                                  children:
                                      list.map<Widget>((FVBModelClass model) {
                                    return Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: EditableTextView(
                                                  model.name,
                                                  onChange: (data) {
                                                    setState(() {
                                                      final temp = Processor
                                                          .classes
                                                          .remove(model.name);
                                                      temp?.fvbFunctions
                                                          .remove(model.name);
                                                      model.name = data;
                                                      Processor.classes[data] =
                                                          temp!;
                                                      model.createConstructor();
                                                    });
                                                    _modelCubit.changed(model);
                                                  },
                                                  key: ObjectKey(model.name),
                                                ),
                                              ),
                                              AppIconButton(
                                                onPressed: () {
                                                  _modelCubit.changed(model);
                                                },
                                                icon: Icons.refresh,
                                                iconColor: Colors.black,
                                              ),
                                              10.wBox,
                                              DeleteIconButton(onPressed: () {
                                                showConfirmDialog(
                                                    title: 'Alert!',
                                                    subtitle:
                                                        'Do you want to delete this model?',
                                                    context: context,
                                                    positive: 'Yes',
                                                    negative: 'No',
                                                    onPositiveTap: () {
                                                      Processor.classes
                                                          .remove(model.name);
                                                      collection.project!
                                                          .processor.variables
                                                          .remove(
                                                              model.listName);
                                                    });
                                              })
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          AddVariableTile(model: model),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          ...model.fvbVariables.values
                                              .map((variable) {
                                            return VariableViewer(
                                              fvbVariable: variable(),
                                              onDelete: (v) {
                                                model.fvbVariables
                                                    .remove(v.name);
                                                _modelCubit.changed(model);
                                                setState(() {});
                                              },
                                            );
                                          })
                                        ],
                                      ),
                                    );
                                  }).toList(growable: false),
                                ),
                              Column(
                                children: Processor.classes.values
                                    .whereType<FVBModelClass>()
                                    .map<Widget>((FVBModelClass model) {
                                  return Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          EditableTextView(
                                            model.listName,
                                            onChange: (data) {
                                              final temp = _collection
                                                  .project!.variables
                                                  .remove(model.listName);
                                              model.listName = data;
                                              _collection.project!
                                                  .variables[data] = temp!;
                                              setState(() {});
                                              _modelCubit.changed(model);
                                            },
                                            key: ObjectKey(model.name),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          AddModelValue(model: model),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          ModelValues(
                                            model: model,
                                          )
                                        ],
                                      ));
                                }).toList(growable: false),
                              ),
                            ],
                          ),
                        ),
                      ))
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class VariableViewer extends StatefulWidget {
  final FVBVariable fvbVariable;
  final void Function(FVBVariable)? onDelete;

  const VariableViewer({Key? key, required this.fvbVariable, this.onDelete})
      : super(key: key);

  @override
  State<VariableViewer> createState() => _VariableViewerState();
}

class _VariableViewerState extends State<VariableViewer> {
  bool editMode = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Text(
            widget.fvbVariable.name,
            style: AppFontStyle.lato(13),
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              widget.fvbVariable.dataType.toString() +
                  (widget.fvbVariable.nullable ? '?' : ''),
              style: AppFontStyle.lato(13,
                  color: ColorAssets.theme, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          if (widget.fvbVariable.value != null) ...[
            Text(
              widget.fvbVariable.value.toString(),
              style: AppFontStyle.lato(13,
                  color: ColorAssets.black, fontWeight: FontWeight.w500),
            ),
            const SizedBox(
              width: 20,
            ),
          ],
          AppIconButton(
            icon: Icons.edit,
            iconColor: theme.iconColor1,
            size: 12,
            onPressed: () {},
          ),
          const SizedBox(
            width: 8,
          ),
          if (widget.onDelete != null)
            DeleteIconButton(
              onPressed: () {
                widget.onDelete?.call(widget.fvbVariable);
              },
            )
        ],
      ),
    );
  }
}

class ModelValues extends StatefulWidget {
  final FVBModelClass model;

  const ModelValues({Key? key, required this.model}) : super(key: key);

  @override
  State<ModelValues> createState() => _ModelValuesState();
}

class _ModelValuesState extends State<ModelValues> {
  final Debounce _debounce = Debounce(const Duration(milliseconds: 400));

  @override
  Widget build(BuildContext context) {
    final instances = widget.model.instances.asMap().entries;
    return ListView.separated(
      itemCount: instances.length,
      shrinkWrap: true,
      itemBuilder: (context, i) {
        final valueList = instances.elementAt(i);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: valueList.key % 2 == 0
                ? const Color(0xfff2f2f2)
                : const Color(0xfff9f9f9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: InkWell(
                      onTap: () {
                        widget.model.instances.remove(valueList.value);
                        BlocProvider.of<ModelCubit>(context)
                            .changed(widget.model);
                        BlocProvider.of<CreationCubit>(context)
                            .changedComponent();
                      },
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      )),
                ),
              ),
              Column(
                children: valueList.value.variables.entries
                    .map((value) => EditVariable(value.value, editable: true,
                            onChanged: (value) {
                          _debounce.run(() {
                            BlocProvider.of<ModelCubit>(context)
                                .changed(widget.model);
                            BlocProvider.of<CreationCubit>(context)
                                .changedComponent();
                          });
                        }, setState2: setState, options: []))
                    .toList(),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}

class AddModelValue extends StatefulWidget {
  final FVBModelClass model;

  const AddModelValue({Key? key, required this.model}) : super(key: key);

  @override
  State<AddModelValue> createState() => _AddModelValueState();
}

class _AddModelValueState extends State<AddModelValue> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
        widget.model.fvbVariables.length, (index) => TextEditingController());
  }

  @override
  void didUpdateWidget(covariant AddModelValue oldWidget) {
    if (_controllers.length != widget.model.fvbVariables.length) {
      _controllers = List.generate(
          widget.model.fvbVariables.length, (index) => TextEditingController());
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.model.fvbVariables.entries;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorAssets.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (_, i) => const SizedBox(
              height: 10,
            ),
            itemBuilder: (_, index) {
              final entry = entries.elementAt(index);
              final instance = entry.value();
              return EditVariable(instance,
                  editable: true,
                  deletable: true,
                  controller: _controllers[index],
                  onChanged: (value) {},
                  setState2: setState, onDelete: (variable) {
                widget.model.fvbVariables.remove(variable.name)!;
                widget.model.instances.forEach((element) {
                  element.variables.remove(variable.name);
                });
                widget.model.createConstructor();
                context.read<ModelCubit>().changed(widget.model);
                context.read<CreationCubit>().changedComponent();
              }, options: []);
              // return SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: Row(
              //     children: [
              //       Text(
              //         instance.name,
              //         style:
              //             AppFontStyle.roboto(14, fontWeight: FontWeight.bold),
              //       ),
              //       const SizedBox(
              //         width: 10,
              //       ),
              //       Expanded(
              //         child: TextField(
              //           controller: _controllers[index],
              //           textInputAction: TextInputAction.next,
              //           decoration: InputDecoration(
              //             contentPadding: const EdgeInsets.all(5),
              //             hintText: instance.name,
              //             enabledBorder: const UnderlineInputBorder(
              //               borderSide:
              //                   BorderSide(color: Colors.black, width: 1),
              //             ),
              //           ),
              //         ),
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.all(5.0),
              //         child: InkWell(
              //             autofocus: false,
              //             canRequestFocus: false,
              //             onTap: () {
              //               widget.model.fvbVariables.remove(entry.key)!;
              //               widget.model.instances.forEach((element) {
              //                 element.variables.remove(entry.key);
              //               });
              //               widget.model.createConstructor();
              //               context.read<ModelCubit>().changed();
              //               context
              //                   .read<ComponentCreationCubit>()
              //                   .changedComponent();
              //             },
              //             child: const Icon(
              //               Icons.delete,
              //               color: Colors.red,
              //               size: 20,
              //             )),
              //       )
              //     ],
              //   ),
              // );
            },
            itemCount: entries.length,
          ),
          const SizedBox(
            height: 10,
          ),
          if (widget.model.fvbVariables.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                width: 80,
                height: 35,
                onPressed: () {
                  final valueList = _controllers.asMap().entries.map((e) {
                    if (e.value.text.isEmpty) {
                      return null;
                    }
                    final dataType = widget.model.fvbVariables.values
                        .elementAt(e.key)()
                        .dataType;
                    return LocalModel.codeToValue(e.value.text, dataType,
                        stringQuote: false);
                  }).toList();
                  if (!valueList.contains(null)) {
                    final Map<String, FVBVariable> vars =
                        _collection.project!.processor.variables;
                    final key = widget.model.listName;
                    final instance = widget.model.createInstance(
                        _collection.project!.processor, valueList);
                    if (vars.containsKey(key)) {
                      (vars[key]!.value as List).add(instance);
                    } else {
                      vars[key] = VariableModel(
                          key,
                          DataType.list(
                              DataType.fvbInstance(widget.model.name)),
                          value: [instance],
                          uiAttached: true,
                          isFinal: true);
                    }

                    setState(() {});
                    context.read<ModelCubit>().changed(widget.model);
                    context.read<CreationCubit>().changedComponent();
                  }
                },
                title: 'ADD',
              ),
            )
        ],
      ),
    );
  }
}

class AddVariableTile extends StatefulWidget {
  final FVBModelClass model;

  const AddVariableTile({Key? key, required this.model}) : super(key: key);

  @override
  State<AddVariableTile> createState() => _AddVariableTileState();
}

class _AddVariableTileState extends State<AddVariableTile> {
  final TextEditingController _controller1 = TextEditingController();
  DataType dataType = DataType.fvbDouble;
  List<DataType>? generics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  height: 35,
                  textInputAction: TextInputAction.next,
                  controller: _controller1,
                  hintText: 'Name',
                ),
              ),
              10.wBox,
              Expanded(
                child: CustomDropdownButton<DataType>(
                  style: AppFontStyle.lato(13),
                  value: dataType,
                  hint: null,
                  items: DataType.modelValues
                      .map<CustomDropdownMenuItem<DataType>>(
                        (e) => CustomDropdownMenuItem<DataType>(
                          value: e,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              e.fvbName ?? e.name,
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
                      if (dataType.fvbName == 'Map') {
                        generics = dataType.generics;
                      }
                    });
                  },
                  selectedItemBuilder: (context, e) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        e.toString(),
                        style:
                            AppFontStyle.lato(14, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                onPressed: _addVariable,
                icon: const Icon(
                  Icons.add,
                  color: Colors.blueAccent,
                ),
              )
            ],
          ),
        ),
        if (generics != null) ...[
          5.hBox,
          LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              alignment: WrapAlignment.start,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int i = 0; i < (dataType.generics?.length ?? 0); i++)
                  SizedBox(
                    width: (constraints.maxWidth / 2) - 10,
                    child: CustomDropdownButton<DataType>(
                      style: AppFontStyle.lato(13),
                      value: generics![i],
                      hint: null,
                      items: DataType.modelValues
                          .map<CustomDropdownMenuItem<DataType>>(
                            (e) => CustomDropdownMenuItem<DataType>(
                              value: e,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  e.toString(),
                                  style: AppFontStyle.lato(14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          generics![i] = value;
                        });
                      },
                      selectedItemBuilder: (context, e) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            e.toString(),
                            style: AppFontStyle.lato(14,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          })
        ]
      ],
    );
  }

  void _addVariable() {
    if (_controller1.text.isNotEmpty) {
      // BlocProvider.of<ComponentOperationCubit>(context,
      //     listen: false)
      //     .addVariable(ComponentOperationCubit
      //     .codeProcessor.variables[name]!);
      final name = _controller1.text;
      final datatype = dataType.copyWith(generics: generics);
      widget.model.fvbVariables[name] =
          () => FVBVariable(name, datatype, isFinal: true);
      widget.model.createConstructor();
      BlocProvider.of<CreationCubit>(context).changedComponent();
      final selectionCubit = BlocProvider.of<SelectionCubit>(context);
      selectionCubit.refresh();

      BlocProvider.of<ModelCubit>(context).changed(widget.model);
      dataType = DataType.fvbDouble;
      setState(() {});
      _controller1.text = '';
    }
  }
}

class AddModelTile extends StatefulWidget {
  const AddModelTile({Key? key}) : super(key: key);

  @override
  State<AddModelTile> createState() => _AddModelTileState();
}

class _AddModelTileState extends State<AddModelTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          title: 'Create Model',
          onPressed: () {
            showEnterInfoDialog(
              context,
              'Enter model name',
              onPositive: (value) {
                AnimatedDialog.hide(context);
                _addModel(value);
              },
            );
          },
        ),
        10.hBox,
        TextButton(
          child: const Text('Convert from Json'),
          onPressed: () {
            _fromJson();
          },
        ),
      ],
    );
  }

  void _addModel(String value) {
    if (value.isNotEmpty) {
      final model = FVBModelClass(value, fvbFunctions: {}, fvbVariables: {});
      Processor.classes[value] = model;
      // final model = LocalModel(_controller.text);

      context.read<ModelCubit>().changed(model);
      context.read<CreationCubit>().changedComponent();
      final componentSelection = context.read<SelectionCubit>();
      componentSelection.refresh();
    }
  }

  void _fromJson() {
    showEnterInfoDialog(context, 'Enter Json', onPositive: (value) {
      try {
        final json = jsonDecode(value);
        final model = CodeOperations.jsonToClass(
          json,
          StringOperation.capitalize('untitled'),
        );
        if (model != null) {
          Processor.classes[model.name] = model;
          context.read<OperationCubit>().updateModels();
          context.read<ModelCubit>().changed(model);
          context.read<CreationCubit>().changedComponent();
          AnimatedDialog.hide(context);
        } else {
          showToast('Can\'t take List, please provide valid json');
        }
      } catch (e) {}
    }, multipleLines: true);
  }
}
