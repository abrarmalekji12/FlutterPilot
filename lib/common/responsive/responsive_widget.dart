import 'package:flutter/material.dart';

import '../../injector.dart';

abstract class BreakPoints {
  static const iPhoneSEWidth = 376;
}

class Responsive extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget desktop;
  final bool useMobileWidgetForTab;
  final bool useDesktopWidgetForLandscapeTab;

  const Responsive({
    this.mobile,
    required this.desktop,
    this.tablet,
    this.useMobileWidgetForTab = true,
    this.useDesktopWidgetForLandscapeTab = true,
    Key? key,
  }) : super(key: key);

  static const mobileTabletLimit = 700;
  static const desktopTabletLimit = 1280;

  // This isMobile, isTablet, isDesktop help us later
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileTabletLimit;

  static bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  static bool isMobileOrTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < desktopTabletLimit;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width <= desktopTabletLimit &&
      MediaQuery.of(context).size.width >= mobileTabletLimit;

  static bool isDesktopOrTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileTabletLimit;

  static double all(BuildContext context, double desktop, double tablet,
      {double? mobile}) {
    if (Responsive.isLandscapeTablet(context) || mobile == null) {
      return tablet;
    } else if (Responsive.isDesktop(context)) {
      return desktop;
    } else {
      return mobile;
    }
  }

  static bool isLandscapeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileTabletLimit &&
      MediaQuery.of(context).size.width <= 1280;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopTabletLimit ||
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopTabletLimit ||
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  static bool isDesktopWidth(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopTabletLimit;

  static bool isForNotDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1500;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (isLandscapeTab) {
      if (useDesktopWidgetForLandscapeTab) {
        return desktop;
      }
      return tablet ?? mobile ?? desktop;
    }
    if (size.width > size.height) {
      return desktop;
    }
    if (size.width >= desktopTabletLimit) {
      return desktop;
    } else if (size.width >= mobileTabletLimit) {
      if (tablet != null) {
        return tablet!;
      } else {
        return useMobileWidgetForTab ? (mobile ?? desktop) : desktop;
      }
    } else {
      return mobile ?? desktop;
    }
  }
}
