// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'menu_style.dart';

// Examples can assume:
// late Widget child;

/// Defines the configuration of the submenus created by the [SubmenuButton],
/// [MenuBar], or [MenuAnchor] widgets.
///
/// Descendant widgets obtain the current [CustomMenuThemeData] object using
/// `MenuTheme.of(context)`.
///
/// Typically, a [CustomMenuThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.menuTheme]. Otherwise, [CustomMenuTheme] can be used to configure
/// its own widget subtree.
///
/// All [CustomMenuThemeData] properties are `null` by default. If any of these
/// properties are null, the menu bar will provide its own defaults.
///
/// See also:
///
/// * [ThemeData], which describes the overall theme for the application.
/// * [MenuBarThemeData], which describes the theme for the menu bar itself in a
///   [MenuBar] widget.
@immutable
class CustomMenuThemeData with Diagnosticable {
  /// Creates a const set of properties used to configure [CustomMenuTheme].
  const CustomMenuThemeData({this.style});

  /// The [MenuStyle] of a [SubmenuButton] menu.
  ///
  /// Any values not set in the [MenuStyle] will use the menu default for that
  /// property.
  final CustomMenuStyle? style;

  /// Linearly interpolate between two menu button themes.
  static CustomMenuThemeData? lerp(
      CustomMenuThemeData? a, CustomMenuThemeData? b, double t) {
    return CustomMenuThemeData(
        style: CustomMenuStyle.lerp(a?.style, b?.style, t));
  }

  @override
  int get hashCode => style.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CustomMenuThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomMenuStyle>('style', style,
        defaultValue: null));
  }
}

/// An inherited widget that defines the configuration in this widget's
/// descendants for menus created by the [SubmenuButton], [MenuBar], or
/// [MenuAnchor] widgets.
///
/// Values specified here are used for [SubmenuButton]'s menu properties that
/// are not given an explicit non-null value.
///
/// See also:
///
/// * [CustomMenuThemeData], a configuration object that holds attributes of a menu
///   used by this theme.
/// * [MenuBarTheme], which does the same thing for the [MenuBar] widget.
/// * [MenuBar], a widget that manages [MenuItemButton]s.
/// * [MenuAnchor], a widget that creates a region that has a submenu.
/// * [MenuItemButton], a widget that is a selectable item in a menu bar menu.
/// * [SubmenuButton], a widget that specifies an item with a cascading submenu
///   in a [MenuBar] menu.
class CustomMenuTheme extends InheritedTheme {
  /// Creates a const theme that controls the configurations for the menus
  /// created by the [SubmenuButton] or [MenuAnchor] widgets.
  const CustomMenuTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties for [MenuBar] and [MenuItemButton] in this widget's
  /// descendants.
  final CustomMenuThemeData data;

  /// Returns the closest instance of this class's [data] value that encloses
  /// the given context. If there is no ancestor, it returns
  /// [ThemeData.menuTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return MenuTheme(
  ///     data: const MenuThemeData(
  ///       style: MenuStyle(
  ///         backgroundColor: WidgetStatePropertyAll<Color>(Colors.red),
  ///       ),
  ///     ),
  ///     child: child,
  ///   );
  /// }
  /// ```
  static CustomMenuThemeData of(BuildContext context) {
    final CustomMenuTheme? menuTheme =
        context.dependOnInheritedWidgetOfExactType<CustomMenuTheme>();
    return menuTheme?.data ?? const CustomMenuThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CustomMenuTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(CustomMenuTheme oldWidget) => data != oldWidget.data;
}
