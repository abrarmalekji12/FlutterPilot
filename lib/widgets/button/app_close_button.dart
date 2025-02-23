import 'package:flutter/material.dart';

import '../../ui/navigation/animated_dialog.dart';

class AppCloseButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppCloseButton({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(context) {
    return IconButton(
      onPressed: onTap ??
          () {
            AnimatedDialog.hide(context);
          },
      visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
      splashRadius: 20,
      icon: const Icon(
        Icons.cancel,
        size: 25,
        color: Color(0xffD4D6E1),
        semanticLabel: '',
      ),
      iconSize: 24,
      color: Colors.black,
      enableFeedback: true,
      alignment: Alignment.center,
    );
  }
}
