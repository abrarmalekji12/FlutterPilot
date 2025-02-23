import 'package:flutter/material.dart';

import '../../constant/color_assets.dart';

class ProfileDynamicImage extends StatelessWidget {
  final String userName;
  final double radius;
  final Color? color;
  final double? fontSize;

  const ProfileDynamicImage({
    Key? key,
    this.color,
    this.fontSize,
    required this.userName,
    required this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final split = userName.split(' ');
    final list = split
        .where((element) => element.replaceAll(' ', '').isNotEmpty)
        .toList(growable: false);
    if (list.isNotEmpty) {
      final combination = (list[0].isNotEmpty ? list[0][0].toUpperCase() : '') +
          (list.length > 1 && list[1].isNotEmpty
              ? (list[1][0].replaceAll(' ', '').toUpperCase())
              : '');
      final f = (radius / 1.15).floorToDouble();
      return AnimatedContainer(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color ??
                Colors.primaries[userName.hashCode % Colors.primaries.length],
            shape: BoxShape.circle,
            border: Border.all(color: ColorAssets.border, width: 0.5)),
        duration: const Duration(milliseconds: 400),
        child: Align(
          child: Text(
            combination,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'arial',
              color: Colors.white,
              fontSize: fontSize ?? f,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: Colors.white,
      ),
    );
  }

  int getHashValueFromUserName(String userName) {
    int value = 0;
    for (int i = 0; i < userName.length; i++) {
      value += (userName[i].codeUnits[0]);
    }
    return value % Colors.primaries.length;
  }
}
