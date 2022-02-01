import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget largeScreen;
  final Widget? mediumScreen;
  final Widget? smallScreen;

  const ResponsiveWidget(
      {required this.largeScreen,
      this.mediumScreen,
      this.smallScreen,
      Key? key})
      : super(key: key);

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 900;
  }

  static bool isSmallScreen2() {
    return Get.width < 900;
  }

  static bool isVerySmallScreen() {
    return Get.width < 350;
  }

  static bool isMediumScreen2() {
    return Get.width >= 900 && Get.width <= 1200;
  }

  static bool isScreenBetween1215() {
    return Get.width >= 1200 && Get.width <= 1500;
  }

  static bool isLargeScreen2() {
    return Get.width > 1200;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900 &&
        MediaQuery.of(context).size.width <= 1200;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return largeScreen;
        } else if (constraints.maxWidth <= 1200 &&
            constraints.maxWidth >= 900) {
          return mediumScreen ?? largeScreen;
        } else {
          return smallScreen ?? largeScreen;
        }
      },
    );
  }
}
