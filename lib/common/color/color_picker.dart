import 'dart:ui' as ui;

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:image/image.dart' as img;

import '../../constant/font_style.dart';
import '../../constant/image_asset.dart';
import '../../ui/parameter_ui.dart';
import '../../widgets/button/app_close_button.dart';
// import '../../widgets/color_picker.dart';
import '../extension_util.dart';

class ColorPickerUI extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onClose;
  final Processor? processor;
  final ValueChanged<String>? onVariablePicked;

  const ColorPickerUI(
      {Key? key,
      required this.color,
      required this.onColorChanged,
      required this.onClose,
      required this.processor,
      this.onVariablePicked})
      : super(key: key);

  @override
  State<ColorPickerUI> createState() => _ColorPickerUIState();
}

class _ColorPickerUIState extends State<ColorPickerUI> {
  final ValueNotifier<Color?> pickedColor = ValueNotifier(null);
  final ValueNotifier<Offset> pickerPosition = ValueNotifier(Offset.zero);
  bool pickerMode = false;
  late img.Image image;
  late Offset position;

  Future<img.Image> _captureSocialPng(BuildContext context) async {
    final RenderRepaintBoundary? boundary = const GlobalObjectKey('repaint')
        .currentContext!
        .findRenderObject() as RenderRepaintBoundary?;
    final ui.Image image = await boundary!.toImage();
    return (await img.decodePng(
        (await image.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List()))!;
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    position = ((const GlobalObjectKey('repaint').currentContext!)
            .findRenderObject() as RenderBox)
        .localToGlobal(Offset.zero);
    image = await _captureSocialPng(context);
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.processor?.getAllColorVariables ?? [];
    final List<Color> colors = [
      Colors.black,
      Colors.white,
      Colors.grey,
      ...Colors.primaries,
    ];
    return Stack(
      alignment: Alignment.center,
      children: [
        if (pickerMode)
          ValueListenableBuilder<Offset>(
              valueListenable: pickerPosition,
              builder: (context, value, _) {
                return Positioned(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pickedColor.value,
                        border: Border.all()),
                  ),
                  left: value.dx - 3,
                  top: value.dy - 3,
                );
              }),
        Positioned.fill(
          child: MouseRegion(
            onHover: pickerMode
                ? (event) {
                    final x = (event.position.dx - position.dx).toInt();
                    final y = (event.position.dy - position.dy).toInt();
                    if (x >= 0 && y >= 0) {
                      final p = image.getPixel(x, y);
                      pickedColor.value = Color.fromARGB(
                          p.a.toInt(), p.r.toInt(), p.g.toInt(), p.b.toInt());
                      pickerPosition.value = event.position;
                      widget.onColorChanged.call(pickedColor.value!);
                    }
                  }
                : null,
            child: GestureDetector(
              onTap: () {
                widget.onClose.call();
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        AlertDialog(
          contentPadding: const EdgeInsets.all(15),
          alignment: Alignment.centerRight,
          titlePadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Pick Color',
                  style: AppFontStyle.titleStyle(),
                ),
              ),
              if (!pickerMode)
                InkWell(
                  onTap: () {
                    setState(() {
                      pickerMode = true;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    Images.colorPicker,
                    width: 24,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              20.wBox,
              AppCloseButton(
                onTap: widget.onClose,
              )
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  shrinkWrap: true,
                  itemBuilder: (context, i) {
                    final color =
                        (list[i].value as FVBInstance).toDart() as Color;
                    Color textColor;
                    if (ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark) {
                      textColor = Colors.white;
                    } else {
                      textColor = Colors.black;
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        widget.onVariablePicked?.call(list[i].name);
                        widget.onClose();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(1, 1),
                                blurRadius: 8)
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${list[i].name}',
                          style: AppFontStyle.lato(
                            12,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: list.length,
                ),
                if (list.isNotEmpty)
                  const SizedBox(
                    height: 10,
                  ),
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
                  shrinkWrap: true,
                  itemBuilder: (context, i) {
                    final color = colors[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        widget.onColorChanged.call(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(1, 1),
                                blurRadius: 8)
                          ],
                        ),
                        alignment: Alignment.center,
                      ),
                    );
                  },
                  itemCount: colors.length,
                ),
                const SizedBox(
                  height: 10,
                ),
                ValueListenableBuilder<Color?>(
                    valueListenable: pickedColor,
                    builder: (context, value, _) {
                      return ColorPicker(
                        recentColors: colorHistory,
                        color: value ?? widget.color,
                        // colorPickerWidth: 180,
                        onColorChanged: widget.onColorChanged,
                        pickersEnabled: {
                          ColorPickerType.both: true,
                          ColorPickerType.primary: true,
                          ColorPickerType.accent: true,
                          ColorPickerType.bw: false,
                          ColorPickerType.custom: false,
                          ColorPickerType.customSecondary: false,
                          ColorPickerType.wheel: true,
                        },
                        // hexInputBar: true,
                        // displayThumbColor: true,
                        // hexInputController: _hexInputController,
                      );
                    }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
