import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_builder/constant/font_style.dart';

class CodeViewerWidget extends StatelessWidget {
  final String code;

  const CodeViewerWidget({Key? key, required this.code}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 600,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SelectableText(
                code,
                style: AppFontStyle.roboto(
                  15,
                  color: const Color(0xff494949),
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
