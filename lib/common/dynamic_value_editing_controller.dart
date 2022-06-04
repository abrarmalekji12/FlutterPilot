import 'package:flutter/material.dart';

import '../constant/app_colors.dart';
import '../constant/font_style.dart';

class DynamicValueEditingController extends TextEditingController {
  final Map<String, Color> codeColorMap = {
    'if': Colors.purple,
    'while': Colors.purple,
  };
  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    final textValue = value.text;
    if (textValue.isEmpty) {
      return const TextSpan(children: []);
    }
    final indexList = <int>[];
    int index = 0;
    bool open = true;
    while (index != -1) {
      if (open) {
        index = textValue.indexOf('{{', index);
      } else {
        index = textValue.indexOf('}}', index);
      }
      if (index != -1) {
        indexList.add(index);
      }
      open = !open;
    }

    if (indexList.length % 2 != 0 || indexList.isEmpty) {
      return TextSpan(text: textValue, style: style);
    }
    final List<TextSpan> spans = [];
    int start = 0;
    for (int i = 0; i < indexList.length; i += 2) {
      spans.add(TextSpan(
          text: textValue.substring(start, indexList[i]), style: style));
      final bold = textValue.substring(indexList[i], indexList[i + 1] + 2);
      spans.add(TextSpan(
          text: bold,
          style: AppFontStyle.roboto(13,
              color: bold.contains(' ') ? Colors.red : AppColors.theme,
              fontWeight: FontWeight.bold)));
      start = indexList[i + 1] + 2;
    }
    spans.add(TextSpan(
        text: textValue.substring(start, textValue.length), style: style));
    return TextSpan(children: spans);
  }
}
