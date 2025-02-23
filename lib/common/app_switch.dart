import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

import '../constant/color_assets.dart';
import '../injector.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool) onToggle;
  final bool disabled;
  const AppSwitch({
    required this.value,
    required this.onToggle,
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      width: 30,
      disabled: disabled,
      toggleSize: 12,
      inactiveColor: theme.background3,
      height: 18,
      value: value,
      onToggle: onToggle,
      activeColor: ColorAssets.theme,
      // Color(0xff4544dd)
      // inactiveThumbColor: Color(0xffcccfd7),
    );
  }
}
