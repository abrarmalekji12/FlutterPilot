import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../common/interactive_viewer/interactive_viewer_centered.dart';
import '../common/web/html_lib.dart';
import '../constant/color_assets.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/operation_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/fvb_ui_core/component/component_model.dart';
import '../models/project_model.dart';
import '../runtime_provider.dart';
import 'connection_painter.dart';
import 'emulation_view.dart';

class Line {
  final GlobalObjectKey key1, key2;

  Line(this.key1, this.key2);
}

class PreviewPage extends StatefulWidget {
  final OperationCubit _componentOperationCubit;

  const PreviewPage(
    this._componentOperationCubit, {
    Key? key,
  }) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final GlobalKey _interactiveViewerKey = GlobalKey();
  final List<Screen> screens = [];
  final List<Line> lines = [];
  late final double width;
  late final double height;

  @override
  void initState() {
    super.initState();
    width = ((widget._componentOperationCubit.project!.screens.length < 10
                    ? 10
                    : widget._componentOperationCubit.project!.screens.length) *
                selectedConfig!.width +
            50.0) /
        1.5;
    height =
        selectedConfig!.width * selectedConfig!.height / selectedConfig!.width;
    if (widget._componentOperationCubit.project!.mainScreen != null) {
      screens.add(widget._componentOperationCubit.project!.mainScreen!);
      findInteraction(widget._componentOperationCubit.project!.mainScreen!);
    }
    for (final screen in widget._componentOperationCubit.project!.screens) {
      if (!screens.contains(screen)) {
        screens.add(screen);
        findInteraction(screen);
      }
    }
  }

  void findInteraction(final Screen screen) {
    screen.rootComponent?.forEachWithClones((comp) {
      if (comp is Clickable) {
        for (final action in (comp as Clickable).actionList) {
          if ((action is NewPageInStackAction ||
                  action is ReplaceCurrentPageInStackAction ||
                  action is ShowCustomDialogInStackAction ||
                  action is ShowBottomSheetInStackAction) &&
              action.arguments[0] != null) {
            if (!screens.contains(action.arguments[0] as Screen)) {
              lines.add(Line(
                  GlobalObjectKey(comp.uniqueId + comp.id),
                  GlobalObjectKey(
                      (action.arguments[0] as Screen).rootComponent!.uniqueId +
                          (action.arguments[0] as Screen).rootComponent!.id)));
              screens.add(action.arguments[0] as Screen);
              findInteraction(action.arguments[0]);
            }
          }
        }
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final area = (widget._componentOperationCubit.project!.uiScreens.length < 10
    //         ? 10
    //         : widget._componentOperationCubit.project!.uiScreens.length) *
    //     ((widget._screenConfigCubit.selectedConfig!.width + 50) * (height + 100));
    return SafeArea(
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // ComponentOperationCubit.changeVariables(
                      //     widget._componentOperationCubit.project!.currentScreen);
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget._componentOperationCubit.project!.name,
                    style: AppFontStyle.lato(15, fontWeight: FontWeight.w500),
                  ),
                ),
                const Spacer(),
                InkWell(
                  highlightColor: Colors.blueAccent.shade200,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    takeScreenShot();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Colors.blueAccent,
                    child: Container(
                      width: 200,
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
                            'Download as Image',
                            style: AppFontStyle.lato(13, color: Colors.white),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RuntimeProvider(
                runtimeMode: RuntimeMode.preview,
                child: LayoutBuilder(builder: (context, constraints) {
                  return OldCustomInteractiveViewer(
                      maxScale: 10,
                      // minScale: dw(context, 100) / width,
                      child: RepaintBoundary(
                        key: _interactiveViewerKey,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                              color: ColorAssets.colorE5E5E5),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: FittedBox(
                              child: Stack(
                                key: const GlobalObjectKey('STACK'),
                                children: [
                                  Wrap(
                                    runAlignment: WrapAlignment.center,
                                    alignment: WrapAlignment.center,
                                    children: screens.map((screen) {
                                      // ComponentOperationCubit.changeVariables(screen);
                                      return Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Padding(
                                            //   padding: const EdgeInsets.all(15),
                                            //   child: Text(
                                            //     screen.name,
                                            //     style: AppFontStyle.roboto(14,
                                            //         fontWeight: FontWeight.w500),
                                            //   ),
                                            // ),
                                            Container(
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                    width: 1.5,
                                                    color: screen ==
                                                            widget
                                                                ._componentOperationCubit
                                                                .project!
                                                                .mainScreen
                                                        ? ColorAssets.theme
                                                        : const Color(
                                                            0xfff3f3f3),
                                                  ),
                                                  color: Colors.white,
                                                  boxShadow:
                                                      kElevationToShadow[2]),
                                              constraints: BoxConstraints(
                                                maxWidth: 0.9 *
                                                    MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    (screens.length),
                                              ),
                                              // height: height,
                                              child: IgnorePointer(
                                                child: EmulationView(
                                                    widget:
                                                        screen.build(context) ??
                                                            Container(),
                                                    screenConfig:
                                                        selectedConfig!),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(growable: false),
                                  ),
                                  if (lines.isNotEmpty)
                                    FutureBuilder(
                                        future: Future.delayed(
                                            const Duration(milliseconds: 300)),
                                        builder: (context, data) {
                                          return CustomPaint(
                                            painter: ConnectionPainter(lines),
                                          );
                                        })
                                ],
                              ),
                            ),
                          ),
                        ),
                      ));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  takeScreenShot() async {
    final RenderRepaintBoundary boundary = _interactiveViewerKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List? pngBytes = byteData?.buffer.asUint8List();
    getAnchorElement(href: 'data:image/png;base64,${base64Encode(pngBytes!)}')
      ..setAttribute('download',
          '${widget._componentOperationCubit.project!.name.toUpperCase()}-FVB-${DateTime.now().toLocal().toIso8601String()}.png')
      ..click();
  }
}
