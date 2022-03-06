import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import 'package:flutter_switch/flutter_switch.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool) onToggle;
  final bool disabled;
  const AppSwitch({required this.value, required this.onToggle, this.disabled=false,Key? key, })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterSwitch(
      width: 40,
      disabled: disabled,
      toggleSize: 15,
      inactiveColor: const Color(0xffC4C4C4),
      height: 20,
      value: value,
      onToggle: onToggle,
      activeColor: AppColors.theme,
      // Color(0xff4544dd)
      // inactiveThumbColor: Color(0xffcccfd7),
    );
  }
}
