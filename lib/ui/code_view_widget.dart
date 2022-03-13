import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/project_model.dart';

class CodeViewerWidget extends StatefulWidget {
  final ComponentOperationCubit componentOperationCubit;

  const CodeViewerWidget({Key? key, required this.componentOperationCubit})
      : super(key: key);

  @override
  State<CodeViewerWidget> createState() => _CodeViewerWidgetState();
}

class _CodeViewerWidgetState extends State<CodeViewerWidget> {
  late UIScreen screen;

  @override
  void initState() {
    super.initState();
    screen = widget.componentOperationCubit.flutterProject!.currentScreen;
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.componentOperationCubit.flutterProject!.code(screen);
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 600,
        height: 600,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                width: 150,
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const FileTile(selected: true, name: 'Lib'),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () {
                                  screen = widget.componentOperationCubit
                                      .flutterProject!.uiScreens[i];
                                  setState(() {});
                                },
                                child: FileTile(
                                  selected: widget.componentOperationCubit
                                          .flutterProject!.uiScreens[i] ==
                                      screen,
                                  name: widget.componentOperationCubit
                                      .flutterProject!.uiScreens[i].name,
                                ),
                              ),
                            );
                          },
                          itemCount: widget.componentOperationCubit
                              .flutterProject!.uiScreens.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SelectableText(
                            code,
                            style: AppFontStyle.roboto(14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                            },
                            child: const Icon(
                              Icons.copy,
                              color: Color(0xff494949),
                            )),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileTile extends StatelessWidget {
  final bool selected;
  final String name;

  const FileTile({Key? key, required this.selected, required this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: selected ? AppColors.theme : const Color(0xfff1f1f1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: AppFontStyle.roboto(13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black),
      ),
    );
  }
}
