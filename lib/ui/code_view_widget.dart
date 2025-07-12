import 'dart:async';
import 'dart:convert';

import 'package:code_text_field/code_text_field.dart';
import 'package:dart_style/dart_style.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:fvb_processor/compiler/fvb_file.dart';
import 'package:fvb_processor/compiler/pub_manager.dart';
import 'package:highlight/languages/dart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../code_generators/firebase_lib_generator.dart';
import '../common/analyzer/package_analyzer.dart';
import '../common/app_button.dart';
import '../common/app_loader.dart';
import '../common/code_box/custom_code_controller.dart';
import '../common/code_box/custom_code_field.dart';
import '../common/common_methods.dart';
import '../common/custom_extension_tile.dart';
import '../common/download_utils.dart';
import '../common/extension_util.dart';
import '../common/fvb_arch/widgets.dart';
import '../common/responsive/responsive_widget.dart';
import '../common/web/io_lib.dart';
import '../components/component_impl.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../constant/preference_key.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../injector.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/project_model.dart';
import '../user_session.dart';
import '../widgets/button/app_close_button.dart';
import '../widgets/loading/overlay_loading_component.dart';
import 'fvb_code_editor.dart';
import 'local_build_generator.dart';
import 'navigation/animated_dialog.dart';

class CodeViewerWidget extends StatefulWidget {
  final FVBFile? code;

  const CodeViewerWidget({
    Key? key, this.code,
  }) : super(key: key);

  @override
  State<CodeViewerWidget> createState() => _CodeViewerWidgetState();
}

FVBFile? selectedFile;
final Map<FVBFile, String> formatErrors = {};

class _CodeViewerWidgetState extends State<CodeViewerWidget> {
  late final CustomCodeController _codeController;
  final ScrollController _controller = ScrollController();
  final DartFormatter _dartFormatter = DartFormatter(
    fixes: StyleFix.all,
  );
  late OperationCubit componentOperationCubit;
  late FVBDirectory rootDirectory;
  final SharedPreferences _preferences = sl();
  final UserSession _userSession = sl();

  final Map<FVBFile, String> codeBase = {};
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    formatErrors.clear();
    componentOperationCubit = context.read<OperationCubit>();
    final theme = editorThemes[_userSession.settingModel!.iDETheme];
    _codeController = CustomCodeController(language: dart, theme: theme);
    backgroundColor = theme!['root']!.backgroundColor;
    if (widget.code != null) {
      rootDirectory = FVBDirectory('', [widget.code!], []);
      selectedFile=widget.code!;
      format(rootDirectory);
    }
    else {
      _initializeCodeGeneration();
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final focusContext = GlobalObjectKey(selectedFile!).currentContext;
      if (focusContext != null) {
        Scrollable.ensureVisible(focusContext, alignment: 0.5);
      }
    });
  }

  void format(FVBPath file) {
    if (file is FVBDirectory) {
      file.files.forEach((element) {
        format(element);
      });
      file.folders.forEach((element) {
        format(element);
      });
    } else if (file is FVBFile) {
      if (file.name.endsWith('.dart')) {
        try {
          file.code = _dartFormatter.format(file.code ?? '');
        } on FormatException catch (e) {
          formatErrors[file] = '${e.message} ${e.offset}';
        } on Exception catch (e) {
          formatErrors[file] = '${e.toString()}';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.isDesktop(context)
          ? MediaQuery
          .of(context)
          .size
          .width * 0.7
          : null,
      height: Responsive.isDesktop(context)
          ? MediaQuery
          .of(context)
          .size
          .height * 0.8
          : null,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Generated Code',
                        style: AppFontStyle.headerStyle(),
                      ),
                      20.wBox,
                      if (kDebugMode)
                        AppIconButton(
                          icon: Icons.refresh,
                          onPressed: () {
                            _initializeCodeGeneration();
                          },
                        )
                    ],
                  ),
                  const AppCloseButton()
                ],
              ),
              Expanded(
                child: Flex(
                  direction: Responsive.isDesktop(context)
                      ? Axis.horizontal
                      : Axis.vertical,
                  children: [
                    SizedBox(
                      width: Responsive.isDesktop(context) ? 250 : null,
                      child: ProjectFileWidget(
                        selectedFile: selectedFile,
                        onChange: (FVBFile value) {
                          _preferences.setString(
                              PrefKey.codeViewSelection, value.path);
                          setState(() {
                            selectedFile = value;
                          });
                        },
                        componentOperationCubit: componentOperationCubit,
                        directory: rootDirectory,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: backgroundColor!,
                        child: ScrollbarTheme(
                          data: ScrollbarTheme.of(context).copyWith(
                            thumbColor:
                            const WidgetStatePropertyAll(Colors.white),
                            trackColor:
                            const WidgetStatePropertyAll(Colors.white),
                            radius: const Radius.circular(10),
                            thickness: const WidgetStatePropertyAll(10),
                          ),
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior()
                                .copyWith(scrollbars: true),
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  controller: _controller,
                                  child: CustomCodeField(
                                    fontSize: 14,
                                    // expands: true,
                                    enabled: true,
                                    readOnly: true,
                                    lineNumberStyle: const LineNumberStyle(
                                      margin: 5,
                                      textStyle: TextStyle(
                                          fontSize: 14,
                                          height: 1.31,
                                          fontFamily: 'arial'),
                                    ),

                                    controller: _codeController
                                      ..text = selectedFile?.code ?? '',
                                  ),
                                ),
                                if (selectedFile?.code != null)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(15),
                                      child: InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(
                                              text: selectedFile?.code ?? ''));
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> formatCode() async {
    if (selectedFile != null) {
      // if(codeBase.containsKey(selectedFile)){
      //   return codeBase[selectedFile]!;
      // }
      String code = '';
      code = selectedFile!.code ?? '';

      if (selectedFile?.name.endsWith('.dart') ?? false) {
        try {
          code = _dartFormatter.format(code);
        } catch (e) {
          print('Formatting error ${e.toString()}');
          formatErrors[selectedFile!] = 'Format Error: ${e.toString()}';
        }
      }
      return code;
    }

    return '';
    // print('Formatting....');
    // try {
    //   code = screen.code(componentOperationCubit.project!);
    // } on Exception catch (e) {
    //   e.printError();
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     showAlertDialog(context, 'Generation Error', e.toString());
    //   });
    // } catch (e) {
    //   e.printError();
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     showAlertDialog(context, 'Generation Error', e.toString());
    //   });
    // }
    // try {
    //   code = _dartFormatter.format(code);
    // } catch (e) {
    //   print('Formatting error ${e.toString()}');
    //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //     showAlertDialog(context, 'Format Error', e.toString());
    //   });
    // }
    // return code;
  }

  void _initializeCodeGeneration() {
    final project = componentOperationCubit.project!;
    final Map<String, List<CommonParam>> commonParams = {};
    for (final commonParam in project.commonParams) {
      final key = commonParam.fileName;
      if (commonParams.containsKey(key)) {
        commonParams[key]!.add(commonParam);
      } else {
        commonParams[key] = [commonParam];
      }
    }
    final mainFile =
    FVBFile('main.dart', componentOperationCubit.project!.code());
    final List<CCustomPaint> customPaints = [];
    [
      ...componentOperationCubit.project!.screens.map((e) => e.rootComponent),
      ...componentOperationCubit.project!.customComponents
          .map((e) => e.rootComponent),
    ].whereType<Component>().forEach((element) {
      element.forEach((p0) {
        if (p0 is CCustomPaint) {
          customPaints.add(p0);
        }
        return false;
      });
    });
    rootDirectory = FVBDirectory(project.packageName, [
      FVBFile('pubspec.yaml', PubManager.code(project))
    ], [
      FVBDirectory('lib', [
        mainFile
      ], [
        FVBDirectory('common', [
          if (project.settings.firebaseConnect != null)
            FVBFile('firebase_lib.dart', FirebaseLibGenerator().generate()),
          FVBFile('extensions.dart', project.extensions()),
          for (final common in commonParams.entries)
            if (common.value.isNotEmpty) FVBFile('${common.key}.dart', '''
     ${PackageAnalyzer.getPackages(project, null, null)} 
          class ${common.value.first.className} {
          ${common.value.map((e) => e.implCode).join('\n')}
          }
          ''')
        ], [
          FVBDirectory('widgets', [
            for (final widgetEntry in addedWidgets.entries)
              FVBFile('${widgetEntry.key}.dart', widgetEntry.value)
          ], []),
          if (customPaints.isNotEmpty)
            FVBDirectory('painters', [
              for (final entry in customPaints)
                FVBFile(
                  '${entry.import!}.dart',
                  entry.implCode,
                )
            ], []),
        ]),
        FVBDirectory('dependency',
            [FVBFile('dependency.dart', project.dependencyCode())], []),
        FVBDirectory('data', [
          FVBFile('dio_client.dart', project.apiModel.dioClientCode()),
          FVBFile('apis.dart', project.apiModel.apisCode()),
        ], [
          FVBDirectory('models', [
            for (final model
            in Processor.classes.values.whereType<FVBModelClass>())
              FVBFile(model.fileName + '.dart', model.implCode(project))
          ], [])
        ]),
        FVBDirectory('ui', [], [
          FVBDirectory('page', [
            for (final screen in project.screens)
              FVBFile(screen.fileName + '.dart', screen.code(project))
          ], []),
          FVBDirectory('common', [
            for (final custom in project.customComponents)
              FVBFile(
                  custom.fileName + '.dart', custom.implementationCode(project))
          ], [])
        ])
      ]),
    ]);
    final selection = _preferences.getString(PrefKey.codeViewSelection);
    if (selection != null) {
      final path = selection.split('/');
      FVBPath? fvbPath = rootDirectory;
      if (path.isNotEmpty && path[0] == rootDirectory.name) {
        if (path.length >= 2) {
          for (final p in path.sublist(1)) {
            if (p != path.last) {
              fvbPath = fvbPath?.findFolder(p);
            } else {
              fvbPath = fvbPath?.findFile(p);
            }
          }
        }
        if (fvbPath is FVBFile) {
          selectedFile = fvbPath;
        }
      }
    }
    selectedFile ??= mainFile;
    format(rootDirectory);
  }
}

class ProjectFileWidget extends StatefulWidget {
  final FVBDirectory directory;
  final OperationCubit componentOperationCubit;
  final FVBFile? selectedFile;
  final ValueChanged<FVBFile> onChange;

  const ProjectFileWidget({
    Key? key,
    required this.directory,
    required this.componentOperationCubit,
    this.selectedFile,
    required this.onChange,
  }) : super(key: key);

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
    bool downloading = false;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          StatefulBuilder(builder: (context, setStateLoading) {
            return OverlayLoadingComponent(
              radius: 6,
              loading: downloading,
              child: InkWell(
                highlightColor: Colors.blueAccent.shade200,
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setStateLoading(() {
                    downloading = true;
                  });
                  downloadProject().then((value) {
                    setStateLoading(() {
                      downloading = false;
                    });
                  });
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.blueAccent,
                  child: Padding(
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
                          style: AppFontStyle.lato(13, color: Colors.white),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InkWell(
              highlightColor: Colors.green.shade200,
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                downloadApk();
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.green,
                child: Padding(
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
                        'Build Apk',
                        style: AppFontStyle.lato(13, color: Colors.white),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(5),
              child: FileTile(
                directory: widget.directory,
                selectedFile: widget.selectedFile,
                onChange: widget.onChange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildContainer() {
  //   return Container(
  //     padding: Responsive.isLargeScreen(context)
  //         ? const EdgeInsets.only(left: 10, top: 10)
  //         : EdgeInsets.zero,
  //     child: ListView.builder(
  //       padding: EdgeInsets.zero,
  //       shrinkWrap: true,
  //       scrollDirection:
  //       Responsive.isLargeScreen(context) ? Axis.vertical : Axis.horizontal,
  //       itemBuilder: (_, i) {
  //         return Padding(
  //           padding: Responsive.isLargeScreen(context)
  //               ? const EdgeInsets.only(bottom: 10)
  //               : const EdgeInsets.only(left: 10),
  //           child: InkWell(
  //             onTap: () {
  //               widget.onChange(
  //                   widget.componentOperationCubit.project!.uiScreens[i]);
  //             },
  //             child: FileTile(
  //               selected:
  //               widget.componentOperationCubit.project!.uiScreens[i] ==
  //                   widget.screen,
  //               name: widget.componentOperationCubit.project!.uiScreens[i].name,
  //             ),
  //           ),
  //         );
  //       },
  //       itemCount: widget.componentOperationCubit.project!.uiScreens.length,
  //     ),
  //   );
  // }

  Map<String, dynamic> generateCode() {
    final images =
        widget.componentOperationCubit.project?.getAllUsedImages() ?? [];
    final Map<String, dynamic> imageToBase64Map = {};
    for (final img in images) {
      if (img.bytes != null) {
        imageToBase64Map['assets/images/' + img.name!] = img.bytes!;
      }
    }
    addFilesOfFolder(imageToBase64Map, widget.directory, '');
    if (formatErrors.isNotEmpty) {
      showConfirmDialog(
          title: 'Error generating code',
          subtitle:
          'Error with files\n${formatErrors.entries.map((e) => '${e.key}: ${e.value}').join('\n')}',
          context: context,
          positive: 'Ok');
    }
    return imageToBase64Map;
  }

  String _formatDartCode(FVBFile file, String code) {
    try {
      return formatter.format(code);
    } catch (e) {
      print('FORMAT ERROR: ${file.path} :: ${e.toString()}');
      formatErrors[file] = e.toString();
    }
    return code;
  }

  void addFilesOfFolder(imageToBase64Map, FVBDirectory directory, String path) {
    for (final file in directory.files) {
      imageToBase64Map[(path.isNotEmpty ? '$path/' : '') + file.name] =
      file.name.endsWith('.dart')
          ? _formatDartCode(file, file.code ?? '')
          : file.code ?? '';
    }
    for (final folder in directory.folders) {
      addFilesOfFolder(imageToBase64Map, folder,
          path.isEmpty ? folder.name : '$path/${folder.name}');
    }
  }

  void downloadApk() async {
    final generatedCode = generateCode();
    if (Platform.isWindows || Platform.isMacOS) {
      final path = await DownloadUtils.downloadWithoutZip(
          generatedCode, widget.componentOperationCubit.project!.packageName);
      if (path != null) {
        AnimatedDialog.show(
          context,
          LocalBuildGenerator(
            path: path,
          ),
          key: '__',
        );
      } else {
        showConfirmDialog(
            title: 'Error',
            subtitle: 'Couldn\'t save code',
            context: context,
            positive: 'ok');
      }
    } else {
      AppLoader.show(context);
      http
          .post(Uri.parse('http://127.0.0.1:8000/generate'),
          body: jsonEncode(generatedCode))
          .then((response) {
        AppLoader.hide(context);

        if (response.statusCode == 200) {
          showConfirmDialog(
              context: context,
              title: 'Build Success',
              subtitle: 'Saving apk in Downloads',
              positive: 'ok');
          FileSaver.instance
              .saveFile(
              name: 'app-release', bytes: response.bodyBytes, ext: 'apk')
              .then((value) {
            showConfirmDialog(
                context: context,
                title: 'Saved Successfully',
                subtitle: 'Release Apk is saved in Downloads',
                positive: 'ok');
          }).onError((error, stackTrace) {
            showConfirmDialog(
                context: context,
                title: 'Error while saving',
                subtitle: error.toString(),
                positive: 'Ok');
          });
        } else {
          showConfirmDialog(
              context: context,
              title: 'Error building',
              subtitle: response.body,
              positive: 'Ok');
        }
      }).catchError((error) {
        AppLoader.hide(context);
        showConfirmDialog(
            context: context,
            title: 'Error building',
            subtitle: error.toString(),
            positive: 'Ok');
      });
    }
  }

  Future<bool> downloadProject() async {
    final imageToBase64Map = generateCode();
    return await DownloadUtils.downloadWithoutZip(imageToBase64Map,
        widget.componentOperationCubit.project!.packageName)
        .then((value) async {
      // final path = sl<UserSession>().settingModel?.otherSettings?.flutterPath;
      // if (path != null) {
      //   final shell = Shell();
      //   await shell.run('cd C:/Users/abrar/Downloads/${widget.componentOperationCubit.project!.packageName}');
      //   final result = await shell.run('${path}/bin/dart fix --apply');
      //   if (result.isNotEmpty) {
      return true;
      // }
      // return false;
      // } else {
      //   return true;
      // }
    });
  }
}

class FileTile extends StatelessWidget {
  final FVBDirectory directory;
  final FVBFile? selectedFile;
  final ValueChanged<FVBFile> onChange;

  FileTile({Key? key,
    required this.directory,
    this.selectedFile,
    required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enable = directory.files.isNotEmpty || directory.folders.isNotEmpty;
    return CustomExpansionTile(
      initiallyExpanded: enable,
      collapsedBackgroundColor: ColorAssets.lightGrey,
      backgroundColor: ColorAssets.lightGrey,
      childrenPadding: EdgeInsets.zero,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          directory.name,
          style: AppFontStyle.lato(
            14,
          ),
        ),
      ),
      trailing: !enable ? const Offstage() : null,
      children: !enable
          ? []
          : [
        Container(
          decoration: BoxDecoration(
              color: theme.background1,
              border: Border(
                left: BorderSide(color: theme.border1, width: 2),
              )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                  separatorBuilder: (context, i) {
                    return const SizedBox(
                      height: 5,
                    );
                  },
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding:
                  const EdgeInsets.only(left: 5, top: 3, bottom: 5),
                  itemCount: directory.folders.length,
                  itemBuilder: (context, i) {
                    return FileTile(
                      directory: directory.folders[i],
                      selectedFile: selectedFile,
                      onChange: onChange,
                    );
                  }),
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(4),
                  itemCount: directory.files.length,
                  itemBuilder: (context, i) {
                    return InkWell(
                      key: GlobalObjectKey(directory.files[i]),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        onChange.call(directory.files[i]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: selectedFile == directory.files[i]
                                ? ColorAssets.theme.withOpacity(0.1)
                                : (formatErrors[directory.files[i]] !=
                                null
                                ? ColorAssets.red.withOpacity(0.3)
                                : null)),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.code,
                              size: 16,
                              color: ColorAssets.theme,
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Expanded(
                              child: Text(
                                directory.files[i].name,
                                style: AppFontStyle.lato(12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
      ],
    );
  }
}
