import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../common/custom_drop_down.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_creation/component_creation_cubit.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/component_selection/component_selection_cubit.dart';
import '../cubit/model/model_cubit.dart';
import '../models/local_model.dart';
import '../models/variable_model.dart';

enum DataType { int, double, string }

class ModelView extends StatefulWidget {
  const ModelView({Key? key}) : super(key: key);

  @override
  _ModelViewState createState() => _ModelViewState();
}

class _ModelViewState extends State<ModelView> {
  bool modelBoxOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                modelBoxOpen = !modelBoxOpen;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Text(
                modelBoxOpen ? 'Hide' : 'Variables',
                style: AppFontStyle.roboto(15,
                    color: Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (modelBoxOpen) const ModelBox()
        ],
      ),
    );
  }
}

class ModelBox extends StatefulWidget {
  const ModelBox({Key? key}) : super(key: key);

  @override
  _ModelBoxState createState() => _ModelBoxState();
}

class _ModelBoxState extends State<ModelBox> {
  late final ComponentOperationCubit _componentOperationCubit;
  final ModelCubit _modelCubit = ModelCubit();

  @override
  void initState() {
    super.initState();
    _componentOperationCubit =
        BlocProvider.of<ComponentOperationCubit>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Card(
        elevation: 5,
        color: Colors.white,
        child: Container(
          height: 500,
          padding: const EdgeInsets.all(10),
          child: BlocProvider(
            create: (context) => _modelCubit,
            child: BlocConsumer<ModelCubit, ModelState>(
              listener: (context, state) {
                if (state is ModelChangedState) {
                  if (!state.add) {
                    _componentOperationCubit.updateModel(state.localModel);
                  } else {
                    _componentOperationCubit.addModel(state.localModel);
                  }
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Models',
                      style:
                          AppFontStyle.roboto(15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    AddModelTile(),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: Column(
                        children: _componentOperationCubit.models.map((model) {
                          return Container(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  model.name,
                                  style: AppFontStyle.roboto(14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                AddVariableTile(model: model),
                                const SizedBox(
                                  height: 10,
                                ),
                                ...model.variables.map((variable) => Container(
                                      padding: const EdgeInsets.all(5),
                                      child: Row(
                                        children: [
                                          Text(
                                            variable.name,
                                            style: AppFontStyle.roboto(13),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Text(
                                            variable.dataType.name,
                                            style: AppFontStyle.roboto(13,
                                                color: AppColors.theme),
                                          ),
                                        ],
                                      ),
                                    ))
                              ],
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: _componentOperationCubit.models.map((model) {
                          return Container(
                              padding: const EdgeInsets.all(5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.name,
                                    style: AppFontStyle.roboto(14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  AddModelValue(model: model),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  ...model.values.map((e) => Column(
                                        children: e
                                            .asMap()
                                            .entries
                                            .map((value) => Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            model
                                                                .variables[
                                                                    value.key]
                                                                .name,
                                                            style: AppFontStyle
                                                                .roboto(13),
                                                          ),
                                                          const SizedBox(
                                                            width: 20,
                                                          ),
                                                          Text(
                                                            value.value
                                                                .toString(),
                                                            style: AppFontStyle
                                                                .roboto(13,
                                                                    color: AppColors
                                                                        .theme),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ))
                                ],
                              ));
                        }).toList(growable: false),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

class AddModelValue extends StatefulWidget {
  final LocalModel model;

  const AddModelValue({Key? key, required this.model}) : super(key: key);

  @override
  State<AddModelValue> createState() => _AddModelValueState();
}

class _AddModelValueState extends State<AddModelValue> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _controllers = List.generate(
        widget.model.variables.length, (index) => TextEditingController());

    return Container(
      decoration: BoxDecoration(
          color: const Color(0xfff2f2f2),
          borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.model.variables
              .asMap()
              .entries
              .map(
                (entry) => SizedBox(
                  width: 150,
                  height: 50,
                  child: Row(
                    children: [
                      Text(
                        entry.value.name,
                        style: AppFontStyle.roboto(14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controllers[entry.key],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(5),
                            hintText: entry.value.name,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          const SizedBox(
            height: 5,
          ),
          ElevatedButton(
              onPressed: () {
                final valueList = _controllers.asMap().entries.map((e) {
                  if (e.value.text.isEmpty) {
                    return null;
                  }
                  switch (widget.model.variables[e.key].dataType) {
                    case DataType.int:
                      return int.tryParse(e.value.text);
                    case DataType.double:
                      return double.tryParse(e.value.text);
                    case DataType.string:
                      return e.value.text;
                  }
                }).toList();
                if (!valueList.contains(null)) {
                  widget.model.values.add(valueList);
                  BlocProvider.of<ModelCubit>(context, listen: false)
                      .changed(widget.model);
                }
              },
              child: Text(
                'ADD',
                style: AppFontStyle.roboto(14, color: Colors.white),
              ))
        ],
      ),
    );
  }
}

class AddVariableTile extends StatefulWidget {
  final LocalModel model;

  const AddVariableTile({Key? key, required this.model}) : super(key: key);

  @override
  State<AddVariableTile> createState() => _AddVariableTileState();
}

class _AddVariableTileState extends State<AddVariableTile> {
  final TextEditingController _controller1 = TextEditingController();
  DataType dataType = DataType.double;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller1,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(5),
                hintText: 'Variable Name',
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
                ' of type ',
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
                    style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          IconButton(
            onPressed: () {
              if (_controller1.text.isNotEmpty) {
                // BlocProvider.of<ComponentOperationCubit>(context,
                //     listen: false)
                //     .addVariable(ComponentOperationCubit
                //     .codeProcessor.variables[name]!);

                widget.model.variables
                    .add(DynamicVariableModel(_controller1.text, dataType));
                BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                    .changedComponent();
                BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                    .emit(ComponentSelectionChange());

                BlocProvider.of<ModelCubit>(context, listen: false)
                    .changed(widget.model);

                setState(() {});
                _controller1.text = '';
              }
            },
            icon: const Icon(
              Icons.add,
              color: Colors.blueAccent,
            ),
          )
        ],
      ),
    );
  }
}

class AddModelTile extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  AddModelTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Name',
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
              if (_controller.text.isNotEmpty) {
                final model = LocalModel(_controller.text);
                BlocProvider.of<ComponentOperationCubit>(context, listen: false)
                    .models
                    .add(model);
                BlocProvider.of<ComponentCreationCubit>(context, listen: false)
                    .changedComponent();
                BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
                    .emit(ComponentSelectionChange());
                BlocProvider.of<ModelCubit>(context, listen: false)
                    .changed(model,add:true);
                _controller.text = '';
              }
            },
            icon: const Icon(
              Icons.add,
              color: Colors.blueAccent,
            ),
          )
        ],
      ),
    );
  }
}
