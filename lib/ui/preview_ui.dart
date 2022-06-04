import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import '../common/custom_popup_menu_button.dart';
import '../common/interactive_viewer_centered.dart';
import '../constant/app_colors.dart';
import '../constant/font_style.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import '../cubit/screen_config/screen_config_cubit.dart';
import '../models/actions/action_model.dart';
import '../models/component_model.dart';
import '../models/project_model.dart';
import '../runtime_provider.dart';
import 'connection_painter.dart';
import 'emulation_view.dart';

class Line {
  final GlobalObjectKey key1, key2;

  Line(this.key1, this.key2);
}

class PreviewPage extends StatefulWidget {
  final ComponentOperationCubit _componentOperationCubit;
  final ScreenConfigCubit _screenConfigCubit;

  const PreviewPage(
    this._componentOperationCubit,
    this._screenConfigCubit, {
    Key? key,
  }) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final GlobalKey _interactiveViewerKey = GlobalKey();
  final List<UIScreen> screens = [];
  final List<Line> lines = [];
  late final double width;
  late final double height;

  @override
  void initState() {
    super.initState();
    width =
        ((widget._componentOperationCubit.flutterProject!.uiScreens.length < 10
                        ? 10
                        : widget._componentOperationCubit.flutterProject!
                            .uiScreens.length) *
                    widget._screenConfigCubit.screenConfig.width +
                50.0) /
            1.5;
    height = widget._screenConfigCubit.screenConfig.width *
        widget._screenConfigCubit.screenConfig.height /
        widget._screenConfigCubit.screenConfig.width;
    screens.add(widget._componentOperationCubit.flutterProject!.mainScreen);
    findInteraction(widget._componentOperationCubit.flutterProject!.mainScreen);
    for (final screen
        in widget._componentOperationCubit.flutterProject!.uiScreens) {
      if (!screens.contains(screen)) {
        screens.add(screen);
        findInteraction(screen);
      }
    }
  }

  void findInteraction(final UIScreen screen) {
    screen.rootComponent?.forEach((comp) {
      if (comp is Clickable) {
        for (final action in (comp as Clickable).actionList) {
          if ((action is NewPageInStackAction ||
                  action is ReplaceCurrentPageInStackAction ||
                  action is ShowCustomDialogInStackAction ||
                  action is ShowBottomSheetInStackAction) &&
              action.arguments[0] != null) {
            if (!screens.contains(action.arguments[0] as UIScreen)) {
              lines.add(Line(
                  GlobalObjectKey(comp.uniqueId + comp.id),
                  GlobalObjectKey((action.arguments[0] as UIScreen)
                          .rootComponent!
                          .uniqueId +
                      (action.arguments[0] as UIScreen).rootComponent!.id)));
              screens.add(action.arguments[0] as UIScreen);
              findInteraction(action.arguments[0]);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final area =
        (widget._componentOperationCubit.flutterProject!.uiScreens.length < 10
                ? 10
                : widget._componentOperationCubit.flutterProject!.uiScreens
                    .length) *
            ((widget._screenConfigCubit.screenConfig.width + 50) *
                (height + 100));
    return Material(
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
                    ComponentOperationCubit.changeVariables(widget
                        ._componentOperationCubit
                        .flutterProject!
                        .currentScreen);
                    Get.back();
                  },
                  child: const Icon(Icons.arrow_back),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  widget._componentOperationCubit.flutterProject!.name,
                  style: AppFontStyle.roboto(15, fontWeight: FontWeight.w500),
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
                          style: AppFontStyle.roboto(13, color: Colors.white),
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
              child: Builder(builder: (context) {
                return CustomInteractiveViewer(
                    minScale: 0.2,
                    // minScale: dw(context, 100) / width,
                    maxScale: 5.0,
                    constrained: false,
                    child: RepaintBoundary(
                      key: _interactiveViewerKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                            gradient: RadialGradient(
                          colors: [
                            Color(0xd0ffffff),
                            Color(0xd5e8e8e8),
                            Color(0xffb9b9b9),
                          ],
                          radius: 1,
                          center: Alignment.center,
                          tileMode: TileMode.clamp,
                        )),
                        width: width,
                        height: 1.5 * area / width,
                        alignment: Alignment.center,
                        child: Stack(
                          key: const GlobalObjectKey('STACK'),
                          children: [
                            Wrap(
                              runAlignment: WrapAlignment.center,
                              alignment: WrapAlignment.center,
                              children: screens.map((screen) {
                                ComponentOperationCubit.changeVariables(screen);
                                return Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: Text(
                                          screen.name,
                                          style: AppFontStyle.roboto(17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 1.5,
                                              color: screen ==
                                                      widget
                                                          ._componentOperationCubit
                                                          .flutterProject!
                                                          .mainScreen
                                                  ? AppColors.theme
                                                  : const Color(0xfff3f3f3),
                                            ),
                                            color: Colors.white,
                                            boxShadow: kElevationToShadow[2]),
                                        width: widget._screenConfigCubit
                                            .screenConfig.width,
                                        // height: height,
                                        child: IgnorePointer(
                                          child: EmulationView(
                                              widget: screen.build(context) ??
                                                  Container(),
                                              screenConfig: widget
                                                  ._screenConfigCubit
                                                  .screenConfig),
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
                                      painter: ConnectionPainter(
                                          lines,
                                          widget
                                              ._screenConfigCubit.screenConfig),
                                    );
                                  })
                          ],
                        ),
                      ),
                    ));
              }),
            ),
          ),
        ],
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
    AnchorElement(href: 'data:image/png;base64,${base64Encode(pngBytes!)}')
      ..setAttribute('download',
          '${widget._componentOperationCubit.flutterProject!.name.toUpperCase()}-FVB-${DateTime.now().toLocal().toIso8601String()}.png')
      ..click();
  }
}
