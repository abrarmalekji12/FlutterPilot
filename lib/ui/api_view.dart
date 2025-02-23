import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:json_view/json_view.dart';
// import 'package:json_view/json_view.dart';

import '../bloc/api_bloc/api_bloc.dart';
import '../common/api/api_model.dart';
import '../common/app_button.dart';
import '../common/custom_drop_down.dart';
import '../common/package/custom_textfield_searchable.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../injector.dart';
import '../widgets/button/app_close_button.dart';
import 'error_widget.dart';
import 'fvb_code_editor.dart';
import 'home/landing_page.dart';
import 'navigation/animated_dialog.dart';
import 'project/project_selection_page.dart';
import 'variable_ui.dart';

class ApiView extends StatefulWidget {
  const ApiView({Key? key}) : super(key: key);

  @override
  State<ApiView> createState() => _ApiViewState();
}

class _ApiViewState extends State<ApiView> {
  final _componentOperationCubit = sl<OperationCubit>();
  final controller = ScrollController();

  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      padding: const EdgeInsets.symmetric(horizontal: 15).copyWith(top: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Apis',
                    style: AppFontStyle.headerStyle(),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  AppIconButton(
                    icon: Icons.add,
                    size: 20,
                    iconColor: theme.background1,
                    background: ColorAssets.theme,
                    onPressed: () {
                      _componentOperationCubit.project!.apiModel.apis.add(
                        ApiDataModel(
                            'untitled',
                            '',
                            'GET',
                            [],
                            RawBodyModel(),
                            true,
                            ApiSettings(),
                            _componentOperationCubit
                                .project!.apiModel.processor),
                      );
                      _debouncer.run(() {
                        _componentOperationCubit.updateApiData();
                      });
                      setState(() {});
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        controller.jumpTo(controller.position.maxScrollExtent);
                      });
                    },
                    margin: 5,
                  ),
                ],
              ),
              AppCloseButton(
                onTap: () => AnimatedDialog.hide(context),
              )
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          SelectableText(
            'Access through App.apis.NAME.fetch(NAMED_ARGUMENTS)',
            style: AppFontStyle.lato(
              14,
              color: theme.text1Color.withOpacity(0.7),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Global Variables',
            style: AppFontStyle.titleStyle(),
          ),
          const SizedBox(
            height: 8,
          ),
          AddVariableWidget(
              onAdded: (value) {
                _componentOperationCubit
                    .project!.apiModel.processor.variables[value.name] = value;
                _componentOperationCubit.updateApiData();
                setState(() {});
              },
              processor: _componentOperationCubit.project!.apiModel.processor),
          const SizedBox(
            height: 10,
          ),
          for (final variable in _componentOperationCubit
              .project!.apiModel.processor.variables.values) ...[
            EditVariable(variable,
                onChanged: (value) {
                  _debouncer.run(() {
                    _componentOperationCubit.updateApiData();
                  });
                },
                setState2: setState,
                onDelete: (value) {
                  _componentOperationCubit.project!.apiModel.processor.variables
                      .remove(value.name);
                  _debouncer.run(() {
                    _componentOperationCubit.updateApiData();
                  });
                },
                options: []),
            const SizedBox(
              height: 10,
            ),
          ],
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: _componentOperationCubit.project!.apiModel.apis.length,
              itemBuilder: (context, i) => AddApiModelTile(
                model: _componentOperationCubit.project!.apiModel.apis[i],
                onDelete: () {
                  setState(() {});
                },
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class AddApiModelTile extends StatefulWidget {
  final ApiDataModel model;
  final VoidCallback onDelete;

  const AddApiModelTile({Key? key, required this.model, required this.onDelete})
      : super(key: key);

  @override
  State<AddApiModelTile> createState() => _AddApiModelTileState();
}

class _AddApiModelTileState extends State<AddApiModelTile> {
  final _componentOperationCubit = sl<OperationCubit>();

  final TextEditingController _name = TextEditingController(),
      _url = TextEditingController();
  final _apiBloc = sl<FVBApiBloc>();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final List<String> methodList = ['GET', 'POST', 'PUT', 'DELETE'];

  @override
  void initState() {
    _name.text = widget.model.name;
    _url.text = widget.model.baseURL;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Container(
        decoration: BoxDecoration(color: theme.background1, boxShadow: [
          BoxShadow(
              color: theme.foregroundColor1.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(1, 1))
        ]),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: EditableText(
                    controller: _name,
                    onChanged: (String value) {
                      widget.model.name = value;
                      _debouncer.run(() {
                        _componentOperationCubit.updateApiData();
                      });
                    },
                    focusNode: FocusNode(),
                    style: AppFontStyle.lato(
                      16,
                      color: theme.text1Color,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: theme.text1Color,
                    backgroundCursorColor: theme.background1,
                  ),
                ),
                DeleteIconButton(onPressed: () {
                  _componentOperationCubit.project!.apiModel.apis
                      .remove(widget.model);
                  _componentOperationCubit.updateApiData();
                  widget.onDelete.call();
                })
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Arguments',
              style: AppFontStyle.titleStyle(),
            ),
            const SizedBox(
              height: 6,
            ),
            AddVariableWidget(
                onAdded: (value) {
                  widget.model.processor.variables[value.name] = value;
                  _debouncer.run(() {
                    _componentOperationCubit.updateApiData();
                  });
                  setState(() {});
                },
                processor:
                    _componentOperationCubit.project!.apiModel.processor),
            const SizedBox(
              height: 6,
            ),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TitleDropDownRow<String>(
                    list: methodList,
                    value: widget.model.method,
                    onChange: (value) {
                      widget.model.method = value;
                      _debouncer.run(() {
                        _componentOperationCubit.updateApiData();
                      });
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: FVBCodeEditor(
                    controller: _url,
                    onCodeChange: (String value, refresh) {
                      widget.model.baseURL = value;
                      _debouncer.run(() {
                        _componentOperationCubit.updateApiData();
                      });
                    },
                    code: widget.model.baseURL,
                    config: FVBEditorConfig(
                        string: true,
                        shrink: true,
                        smallBottomBar: true,
                        multiline: false),
                    onErrorUpdate: (message, bool er) {},
                    processor: widget.model.processor,
                  ),
                ),
                AppButton(
                  height: 35,
                  width: 70,
                  enabledColor: ColorAssets.theme,
                  title: 'Send',
                  onPressed: () {
                    final processed = widget.model.process();
                    if (processed.isLeft)
                      _apiBloc.add(ApiTestEvent(processed.left));
                    else {
                      _apiBloc.add(ApiProcessingErrorEvent(processed.right));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            for (final variable in widget.model.processor.variables.values) ...[
              EditVariable(variable,
                  onChanged: (value) {
                    setState(() {});
                    _debouncer.run(() {
                      _componentOperationCubit.updateApiData();
                    });
                  },
                  setState2: setState,
                  onDelete: (value) {
                    widget.model.processor.variables.remove(value.name);
                    setState(() {});
                    _debouncer.run(() {
                      _componentOperationCubit.updateApiData();
                    });
                  },
                  options: []),
              const SizedBox(
                height: 8,
              ),
            ],
            // TitleTextFieldRow(
            //   title:,
            //   controller: _url,
            //   onChanged: (String value) {
            //     _debouncer.run(() {
            //       widget.model.baseURL = value;
            //
            //       _componentOperationCubit.updateApiData();
            //     });
            //   },
            // ),
            const SizedBox(
              height: 8,
            ),
            HeaderDataWidget(
              header: widget.model.header,
              model: widget.model,
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 300,
              child: CheckboxListTile(
                value: widget.model.convertToDart,
                onChanged: (value) {
                  if (value != null) {
                    widget.model.convertToDart = value;
                    setState(() {});
                    _debouncer.run(() {
                      _componentOperationCubit.updateApiData();
                    });
                  }
                },
                title: Text(
                  'Convert Response to Dart Class',
                  style: AppFontStyle.lato(14),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (widget.model.body is RawBodyModel)
              RawBodyWidget(
                  apiModel: widget.model,
                  model: widget.model.body as RawBodyModel,
                  processor: widget.model.processor,
                  onChange: (value) {
                    _debouncer.run(() {
                      _componentOperationCubit.updateApiData();
                    });
                  }),
            // CheckboxListTile(
            //   value: widget.model.convertToDart,
            //   onChanged: (value) {
            //     if (value != null) {
            //       widget.model.convertToDart = value;
            //       setState(() {});
            //       _debouncer.run(() {
            //         _componentOperationCubit.updateApiData();
            //       });
            //     }
            //   },
            //   title: Text(
            //     'Convert to dart',
            //     style: AppFontStyle.roboto(14, fontWeight: FontWeight.w500),
            //   ),
            // ),
            BlocBuilder<FVBApiBloc, FVBApiState>(
                bloc: _apiBloc,
                builder: (context, state) {
                  if (state is ApiLoadingState &&
                      state.processed.name == widget.model.name) {
                    return const LinearProgressIndicator(
                      color: ColorAssets.theme,
                    );
                  }
                  if (state is ApiProcessingErrorState) {
                    return ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.list.length,
                        itemBuilder: (context, i) {
                          return ConsoleMessageTile(
                            consoleMessage: ConsoleMessage(
                              state.list[i],
                              ConsoleMessageType.error,
                            ),
                          );
                        });
                  }
                  if (state is ApiResponseState &&
                      state.processed.name == widget.model.name) {
                    dynamic jsonBody;
                    try {
                      jsonBody =
                          json.decode(state.model.body?.toString() ?? 'null');
                    } on FormatException {}
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DefaultTextStyle(
                          style: AppFontStyle.lato(14,
                              color: state.model.error != null
                                  ? Colors.red
                                  : Colors.green.shade700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Response',
                                style: AppFontStyle.titleStyle(),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              SelectableText(
                                'Status : ${state.model.status}',
                                style: AppFontStyle.lato(14,
                                    color: state.model.status == 200 ||
                                            state.model.status == 201 ||
                                            state.model.status == 100
                                        ? Colors.green.shade700
                                        : ColorAssets.red,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Row(
                                children: [
                                  SelectableText(
                                    'Body',
                                    style: AppFontStyle.lato(14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  if (state.model.body != null)
                                    CopyIconButton(text: state.model.body!)
                                ],
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              if (jsonBody != null)
                                SelectionArea(
                                  child: JsonView(
                                    json: jsonBody,
                                    shrinkWrap: true,
                                    animation: true,
                                  ),
                                )
                              else
                                SelectableText(
                                  state.model.body?.toString() ?? 'null',
                                  style: AppFontStyle.lato(14),
                                ),
                              const SizedBox(
                                height: 8,
                              ),
                              if (state.model.error != null) ...[
                                SelectableText(
                                  'Error',
                                  style: AppFontStyle.lato(15,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                SelectableText(
                                  state.model.error?.toString() ?? 'null',
                                  style: AppFontStyle.lato(14),
                                )
                              ],
                              const SizedBox(
                                height: 5,
                              ),
                              if (state.model.headers?.entries.isNotEmpty ??
                                  false) ...[
                                SelectableText(
                                  'Headers',
                                  style: AppFontStyle.lato(15,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                for (final MapEntry<String, List<String>> entry
                                    in (state.model.headers?.entries.toList() ??
                                        []))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Row(
                                      children: [
                                        SelectableText(
                                          entry.key,
                                          style: AppFontStyle.lato(14),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Flexible(
                                          child: SelectableText(
                                            entry.value.join('\n'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ]
                            ],
                          )),
                    );
                  }
                  return const Offstage();
                })
          ],
        ),
      ),
    );
  }
}

class HeaderDataWidget extends StatefulWidget {
  final List<HeaderTile> header;
  final ApiDataModel model;

  const HeaderDataWidget({Key? key, required this.header, required this.model})
      : super(key: key);

  @override
  State<HeaderDataWidget> createState() => _HeaderDataWidgetState();
}

class _HeaderDataWidgetState extends State<HeaderDataWidget> {
  final _debouncer = Debouncer(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Headers',
              style: AppFontStyle.titleStyle(),
            ),
            AppIconButton(
              icon: Icons.add,
              size: 16,
              iconColor: theme.background1,
              background: ColorAssets.theme,
              onPressed: () {
                widget.header.add(HeaderTile('', ''));
                _debouncer.run(() {
                  context.read<OperationCubit>().updateApiData();
                });
                setState(() {});
              },
              margin: 3,
            )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        for (final headerTile in widget.header) ...[
          HeaderTileWidget(
            headerTile: headerTile,
            model: widget.model,
            onDelete: (header) {
              widget.header.remove(header);
              _debouncer.run(() {
                context.read<OperationCubit>().updateApiData();
              });
              setState(() {});
            },
          ),
          const SizedBox(
            height: 5,
          ),
        ]
      ],
    );
  }
}

class HeaderTileWidget extends StatefulWidget {
  final HeaderTile headerTile;
  final void Function(HeaderTile) onDelete;
  final ApiDataModel model;

  const HeaderTileWidget(
      {Key? key,
      required this.headerTile,
      required this.onDelete,
      required this.model})
      : super(key: key);

  @override
  State<HeaderTileWidget> createState() => _HeaderTileWidgetState();
}

class _HeaderTileWidgetState extends State<HeaderTileWidget> {
  final TextEditingController _key = TextEditingController(),
      _value = TextEditingController();
  late OperationCubit componentOperationCubit;
  final _debouncer = Debouncer(milliseconds: 400);

  @override
  void initState() {
    _key.text = widget.headerTile.key;
    _value.text = widget.headerTile.value;
    componentOperationCubit = context.read<OperationCubit>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FVBCodeEditor(
            controller: _key,
            onCodeChange: (value, _) {
              widget.headerTile.key = value;
              _debouncer.run(() {
                componentOperationCubit.updateApiData();
              });
            },
            code: widget.headerTile.key,
            onErrorUpdate: (_, bool) {},
            config: FVBEditorConfig(
              multiline: false,
              smallBottomBar: true,
              string: true,
              shrink: true,
            ),
            processor: widget.model.processor,
          ),
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          child: FVBCodeEditor(
            controller: _value,
            onCodeChange: (value, _) {
              widget.headerTile.value = value;
              _debouncer.run(() {
                componentOperationCubit.updateApiData();
              });
            },
            code: widget.headerTile.value,
            onErrorUpdate: (_, bool) {},
            config: FVBEditorConfig(
              multiline: false,
              smallBottomBar: true,
              string: true,
              shrink: true,
            ),
            processor: widget.model.processor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DeleteIconButton(onPressed: () {
            widget.onDelete.call(widget.headerTile);
          }),
        )
      ],
    );
  }
}

class RawBodyWidget extends StatefulWidget {
  final RawBodyModel model;
  final Processor processor;
  final ValueChanged<String> onChange;
  final ApiDataModel apiModel;

  const RawBodyWidget(
      {Key? key,
      required this.model,
      required this.processor,
      required this.onChange,
      required this.apiModel})
      : super(key: key);

  @override
  State<RawBodyWidget> createState() => _RowBodyWidgetState();
}

class _RowBodyWidgetState extends State<RawBodyWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body',
          style: AppFontStyle.titleStyle(),
        ),
        const SizedBox(
          height: 10,
        ),
        Container(
          height: 150,
          child: FVBCodeEditor(
            code: widget.model.code,
            onCodeChange: (code, refresh) {
              widget.model.code = code;
              widget.onChange.call(code);
            },
            onErrorUpdate: (_, bool error) {},
            config: FVBEditorConfig(
              shrink: true,
              smallBottomBar: true,
              multiline: true,
            ),
            processor: widget.processor,
          ),
        ),
      ],
    );
  }
}

class TitleTextFieldRow extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String> onChanged;

  const TitleTextFieldRow(
      {Key? key,
      required this.title,
      required this.controller,
      this.hint,
      required this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 35,
        child: Row(
          children: [
            Text(
              title,
              style: AppFontStyle.lato(13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(
              width: 20,
            ),
            Expanded(
              child: CommonTextField(
                fontSize: 13,
                controller: controller,
                hintText: hint ?? title,
                border: true,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleDropDownRow<T> extends StatelessWidget {
  final String? title;
  final List<T> list;
  final T? value;
  final ValueChanged<T> onChange;
  final String? hint;

  const TitleDropDownRow(
      {Key? key,
      this.title,
      this.hint,
      required this.list,
      this.value,
      required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppFontStyle.lato(13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
        Expanded(
          flex: 3,
          child: CustomDropdownButton<T>(
              style: AppFontStyle.lato(13),
              value: value,
              hint: null,
              items: list
                  .map<CustomDropdownMenuItem<T>>(
                    (e) => CustomDropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: AppFontStyle.lato(
                          13,
                          fontWeight: FontWeight.w500,
                          color: theme.text1Color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                onChange.call(value);
              },
              selectedItemBuilder: (context, value) {
                return Text(
                  value.toString(),
                  style: AppFontStyle.lato(
                    13,
                    fontWeight: FontWeight.w500,
                    color: theme.text1Color,
                  ),
                );
              }),
        ),
      ],
    );
  }
}
