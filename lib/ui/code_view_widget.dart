import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../common/download_utils.dart';
import '../common/responsive/responsive_widget.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../models/project_model.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

class CodeViewerWidget extends StatefulWidget {
  final ComponentOperationCubit componentOperationCubit;

  const CodeViewerWidget({Key? key, required this.componentOperationCubit})
      : super(key: key);

  @override
  State<CodeViewerWidget> createState() => _CodeViewerWidgetState();
}

class _CodeViewerWidgetState extends State<CodeViewerWidget> {
  final CodeController _codeController = CodeController(
      language: dart,
      theme: monokaiSublimeTheme
          .map((key, value) => MapEntry(key, value.copyWith(fontSize: 14))));
  final ScrollController _controller = ScrollController();
  late String code;
  final DartFormatter _dartFormatter = DartFormatter(fixes: []);
  late UIScreen screen;

  @override
  void initState() {
    super.initState();
    screen = widget.componentOperationCubit.project!.currentScreen;
    code = '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 800,
        height: 600,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Flex(
            direction: Responsive.isLargeScreen(context)
                ? Axis.horizontal
                : Axis.vertical,
            children: [
              ProjectFileWidget(
                componentOperationCubit: widget.componentOperationCubit,
                screen: screen,
                onChange: (screen) {
                  this.screen = screen;
                  setState(() {});
                },
                code: code,
              ),
              Expanded(
                child: Padding(
                  padding:
                      Responsive.isLargeScreen(context)?const EdgeInsets.symmetric(vertical: 30, horizontal: 10):const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      Center(
                        child: FutureBuilder<String>(
                            future: formatCode(),
                            key: GlobalKey(),
                            builder: (context, value) {
                              if (value.hasData && value.data != null) {
                                return SingleChildScrollView(
                                  controller: _controller,
                                  child: CodeField(
                                    // expands: true,
                                    enabled: true,
                                    lineNumberStyle: const LineNumberStyle(
                                      margin: 5,
                                      textStyle: TextStyle(
                                          fontSize: 14,
                                          height: 1.31,
                                          color: Colors.white,
                                          fontFamily: 'arial'),
                                    ),

                                    controller: _codeController
                                      ..text = value.data!,
                                  ),
                                );
                              }
                              return Container(
                                color: const Color(0xfff1f1f1),
                                alignment: Alignment.center,
                                child: Text(
                                  'Formatting Code, Please Wait...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                            },
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

  Future<String> formatCode() async {
    try {
      code = _dartFormatter
          .format(code = screen.code(widget.componentOperationCubit.project!));
    } on Exception catch (e) {
      print('ERROR CONVERSION $e');
    }
    return code;
  }
}

class ProjectFileWidget extends StatefulWidget {
  final UIScreen screen;
  final Function(UIScreen) onChange;
  final String code;
  final ComponentOperationCubit componentOperationCubit;

  const ProjectFileWidget(
      {Key? key,
      required this.code,
      required this.componentOperationCubit,
      required this.screen,
      required this.onChange})
      : super(key: key);

  @override
  State<ProjectFileWidget> createState() => _ProjectFileWidgetState();
}

class _ProjectFileWidgetState extends State<ProjectFileWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      width: 250,
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              highlightColor: Colors.blueAccent.shade200,
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                downloadProject(widget.screen, widget.code);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.blueAccent,
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const Spacer(),
                      Text(
                        'Download Project',
                        style: AppFontStyle.roboto(13, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: Responsive.isLargeScreen(context)?150:double.infinity,
                  height:Responsive.isLargeScreen(context)?null:40 ,
                  child: Flex(
                    direction: Responsive.isLargeScreen(context)?Axis.vertical:Axis.horizontal,
                    children: [
                      const FileTile(selected: true, name: 'Lib'),
                      Container(
                        padding: Responsive.isLargeScreen(context)?const EdgeInsets.only(left: 10, top: 10):
                        EdgeInsets.zero,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          scrollDirection: Responsive.isLargeScreen(context)?Axis.vertical:Axis.horizontal,
                          shrinkWrap: true,
                          itemBuilder: (_, i) {
                            return Padding(
                              padding: Responsive.isLargeScreen(context)?const EdgeInsets.only(bottom: 10):const EdgeInsets.only(left: 10),
                              child: InkWell(
                                onTap: () {
                                  widget.onChange(widget.componentOperationCubit
                                      .project!.uiScreens[i]);
                                },
                                child: FileTile(
                                  selected: widget.componentOperationCubit
                                          .project!.uiScreens[i] ==
                                      widget.screen,
                                  name: widget.componentOperationCubit.project!
                                      .uiScreens[i].name,
                                ),
                              ),
                            );
                          },
                          itemCount: widget.componentOperationCubit.project!
                              .uiScreens.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void downloadProject(UIScreen screen, String code) {
    final images =
        widget.componentOperationCubit.project?.getAllUsedImages() ?? [];
    Map<String, dynamic> imageToBase64Map = {};
    for (final img in images) {
      if (img.bytes != null) {
        imageToBase64Map['asset/images/' + img.imageName!] = img.bytes!;
      }
    }
    final DartFormatter formatter = DartFormatter();
    for (final UIScreen uiScreen
        in widget.componentOperationCubit.project?.uiScreens ?? []) {
      final name =
          uiScreen == widget.componentOperationCubit.project?.mainScreen
              ? 'main'
              : uiScreen.name;
      if (uiScreen != screen) {
        imageToBase64Map['lib/$name.dart'] = formatter
            .format(uiScreen.code(widget.componentOperationCubit.project!));
      } else {
        imageToBase64Map['lib/$name.dart'] = code;
      }
    }

    DownloadUtils.download(
        imageToBase64Map, widget.componentOperationCubit.project!.name);
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
