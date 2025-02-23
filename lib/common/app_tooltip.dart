import 'package:flutter/material.dart';

class TooltipWidget extends StatelessWidget {
  final String message;
  final Widget child;
  const TooltipWidget({Key? key, required this.message, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      child: child,
      message: message,
    );
  }
}
