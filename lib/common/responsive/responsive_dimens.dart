import 'package:flutter/cupertino.dart';

import '../../injector.dart';
import 'responsive_widget.dart';

T resConfig<T>(BuildContext context, T desktop,
    {T? mobile,
    T? tablet,
    Map<int, T>? lessThanWidth,
    Map<int, T>? greaterThanWidth,
    Map<int, T>? lessThanHeight,
    Map<int, T>? greaterThanHeight}) {
  if (lessThanWidth != null) {
    final width = MediaQuery.of(context).size.width;
    for (final entry in lessThanWidth.entries) {
      if (width < entry.key) {
        return entry.value;
      }
    }
  } else if (greaterThanWidth != null) {
    final width = MediaQuery.of(context).size.width;
    for (final entry in greaterThanWidth.entries) {
      if (width > entry.key) {
        return entry.value;
      }
    }
  } else if (lessThanHeight != null) {
    final height = MediaQuery.of(context).size.height;
    for (final entry in lessThanHeight.entries) {
      if (height < entry.key) {
        return entry.value;
      }
    }
  } else if (greaterThanHeight != null) {
    final height = MediaQuery.of(context).size.height;
    for (final entry in greaterThanHeight.entries) {
      if (height > entry.key) {
        return entry.value;
      }
    }
  }

  if (Responsive.isDesktop(context) || (mobile == null && tablet == null)) {
    return desktop;
  }
  if ((Responsive.isTablet(context) && tablet != null) || (mobile == null)) {
    return tablet as T;
  }
  return mobile;
}

T res<T>(BuildContext context, T desktop,
    [T? mobile, T? tablet, T? landscapeTab]) {
  if (Responsive.isDesktop(context) || (mobile == null && tablet == null)) {
    if (isLandscapeTab && landscapeTab != null) {
      return landscapeTab;
    }
    return desktop;
  }
  if ((Responsive.isTablet(context) && tablet != null) || (mobile == null)) {
    return tablet as T;
  }
  return mobile;
}

T resSmall<T>(BuildContext context, [T? mobile, T? tablet]) {
  if (tablet != null) {
    if (mobile == null ||
        Responsive.isTablet(context) ||
        Responsive.isDesktop(context)) {
      return tablet;
    }
  }
  return mobile as T;
}

List<Widget> mobile(List<Widget> children) {
  if (platform == PlatformType.phone) {
    return children;
  }
  return [];
}

List<Widget> tablet(List<Widget> children) {
  if (platform == PlatformType.tablet) {
    return children;
  }
  return [];
}

List<Widget> mobileOrTablet(List<Widget> children) {
  if (platform == PlatformType.tablet || platform == PlatformType.phone) {
    return children;
  }
  return [];
}

List<Widget> desktop(List<Widget> children) {
  if (platform == PlatformType.desktop) {
    return children;
  }
  return [];
}

List<Widget> tabletOrDesktop(List<Widget> children) {
  if (platform == PlatformType.desktop || platform == PlatformType.tablet) {
    return children;
  }
  return [];
}

/// [dw] : value of [pt] is between 0 to 1
double dw(BuildContext context, double pt) {
  return MediaQuery.of(context).size.width * pt;
}

/// [dh] : value of [pt] is between 0 to 1
double dh(BuildContext context, double pt) {
  return MediaQuery.of(context).size.height * pt;
}
