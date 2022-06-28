import 'package:flutter/material.dart';

import '../../constant/font_style.dart';
import '../action_code_editor.dart';

class ActionCodeDialog {
  final String code;
  final void Function(String) onChanged;
  late final OverlayEntry _overlayEntry;
  final List<String>? prerequisites;
  final String title;

  ActionCodeDialog(
      {required this.code,
      required this.title,
      required this.onChanged,
      this.prerequisites}) {
    _overlayEntry = OverlayEntry(
      builder: (_) {
        return GestureDetector(
          onTap: () {
            hide();
          },
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: kElevationToShadow[10],
                ),
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppFontStyle.roboto(14,
                              fontWeight: FontWeight.w500),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            _overlayEntry.remove();
                          },
                          child: const Icon(
                            Icons.close,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Expanded(
                      child: ActionCodeEditor(
                          prerequisites: prerequisites ?? [],
                          onCodeChange: onChanged,
                          code: code),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void show(BuildContext context) {
    Overlay.of(context)!.insert(_overlayEntry);
  }

  void hide() {
    _overlayEntry.remove();
  }
}
