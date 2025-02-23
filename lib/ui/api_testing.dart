import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'project/project_selection_page.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../bloc/api_bloc/api_bloc.dart';
import '../common/custom_popup_menu_button.dart';
import '../common/dynamic_value_filed.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../injector.dart';

class ApiTestingView extends StatefulWidget {
  const ApiTestingView({Key? key}) : super(key: key);

  @override
  State<ApiTestingView> createState() => _ApiTestingViewState();
}

class _ApiTestingViewState extends State<ApiTestingView> {
  late FVBApiBloc _apiBloc;
  bool saving = false;
  final _apiNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    _apiBloc = sl<FVBApiBloc>();
    _apiNameController.text = _apiBloc.apiViewModel.url;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _formKey.currentState?.validate();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: Responsive.isDesktop(context)
                  ? dw(context, 60)
                  : double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'URL',
                        style: AppFontStyle.lato(15,
                            color: Colors.black, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 5,
                          ),
                          StatefulBuilder(builder: (context, setState2) {
                            if (saving) {
                              return Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator()),
                              );
                            }
                            return RoundedAppIconButton(
                                iconSize: 20,
                                buttonSize: 40,
                                icon: Icons.save,
                                onPressed: () {
                                  setState2(() {
                                    saving = true;
                                  });
                                  _apiBloc.apiViewModel.save().then((value) {
                                    setState2(() {
                                      saving = false;
                                    });
                                  });
                                },
                                color: Colors.green);
                          }),
                          const SizedBox(
                            width: 5,
                          ),
                          BlocBuilder<FVBApiBloc, FVBApiState>(
                            bloc: _apiBloc,
                            builder: (context, state) {
                              if (state is ApiLoadingState) {
                                return Container(
                                  height: 40,
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      color: ColorAssets.theme,
                                    ),
                                  ),
                                );
                              }
                              return RoundedAppIconButton(
                                  iconSize: 20,
                                  buttonSize: 40,
                                  icon: Icons.send,
                                  onPressed: () {
                                    _apiBloc.add(
                                        ApiFireEvent(_apiBloc.apiViewModel));
                                  },
                                  color: Colors.blueAccent);
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      DropdownButton<String>(
                        onChanged: (value) {
                          if (value != null) {
                            _apiBloc.apiViewModel.method = value;
                            setState(() {});
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            child: Text(
                              'GET',
                              style: AppFontStyle.lato(14, color: Colors.black),
                            ),
                            value: 'GET',
                          ),
                          DropdownMenuItem(
                            child: Text(
                              'POST',
                              style: AppFontStyle.lato(14, color: Colors.black),
                            ),
                            value: 'POST',
                          ),
                        ],
                        value: _apiBloc.apiViewModel.method,
                      ),
                      Expanded(
                        child: DynamicValueField<String>(
                          onProcessedResult: (code, value) {
                            _apiBloc.apiViewModel.url = code;
                            _apiBloc.apiViewModel.urlValue = value;
                            return !Processor.error;
                          },
                          textEditingController: _apiNameController,
                          formKey: _formKey,
                          processor: _apiBloc.processor,
                        ),
                      ),
                    ],
                  ),
                  if (_apiBloc.apiViewModel.method == 'GET') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 200,
                      child: InputTile(
                        onChange: (String code, value) {
                          _apiBloc.apiViewModel.params = code;
                          _apiBloc.apiViewModel.paramValue = value;
                        },
                        processor: _apiBloc.processor,
                        initial: _apiBloc.apiViewModel.params,
                        title: 'param',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 150,
                      child: InputTile(
                        onChange: (String code, value) {
                          _apiBloc.apiViewModel.body = code;
                          _apiBloc.apiViewModel.bodyValue = value;
                        },
                        processor: _apiBloc.processor,
                        initial: _apiBloc.apiViewModel.body,
                        title: 'body',
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 150,
                      child: InputTile(
                        onChange: (String code, value) {
                          _apiBloc.apiViewModel.header = code;
                          _apiBloc.apiViewModel.headerValue = value;
                        },
                        processor: _apiBloc.processor,
                        initial: _apiBloc.apiViewModel.header,
                        title: 'header',
                      ),
                    ),
                  ],
                  BlocBuilder<FVBApiBloc, FVBApiState>(
                      bloc: _apiBloc,
                      builder: (context, state) {
                        if (state is ApiResponseState) {
                          return Expanded(
                            child: DefaultTextStyle(
                                style: AppFontStyle.lato(14,
                                    color: state.model.error != null
                                        ? Colors.red
                                        : Colors.green.shade700),
                                child: ListView(
                                  padding: const EdgeInsets.only(top: 10),
                                  children: [
                                    SelectableText(
                                      'Status : ${state.model.status}',
                                      style: AppFontStyle.lato(15),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    SelectableText(
                                      'Body',
                                      style: AppFontStyle.lato(15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    SelectableText(
                                      state.model.body?.toString() ?? 'null',
                                      style: AppFontStyle.lato(14),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    SelectableText(
                                      'Headers',
                                      style: AppFontStyle.lato(15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    for (final MapEntry<String,
                                        List<String>> entry in (state
                                            .model.headers?.entries
                                            .toList() ??
                                        []))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 5),
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
                                  ],
                                )),
                          );
                        }
                        return const Offstage();
                      })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InputTile extends StatefulWidget {
  final String title;
  final void Function(String, dynamic) onChange;
  final Processor processor;
  final String? initial;

  const InputTile(
      {Key? key,
      required this.title,
      this.initial,
      required this.onChange,
      required this.processor})
      : super(key: key);

  @override
  State<InputTile> createState() => _InputTileState();
}

class _InputTileState extends State<InputTile> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppFontStyle.lato(15,
              color: Colors.black, fontWeight: FontWeight.w500),
        ),
        const SizedBox(
          height: 10,
        ),
        Expanded(
          child: DynamicValueField(
            initialCode: widget.initial,
            onProcessedResult: (code, value) {
              widget.onChange.call(code, value);
              return !Processor.error;
            },
            processor: widget.processor,
            formKey: _formKey,
            expands: true,
          ),
        )
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final void Function(String) onChange;

  const CustomTextField(
      {Key? key, required this.textEditingController, required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      onChanged: onChange,
      decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(10),
          hintText: 'www.example.com',
          border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 1))),
    );
  }
}
