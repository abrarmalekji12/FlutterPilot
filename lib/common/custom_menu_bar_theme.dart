// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'custom_menu_theme.dart';
import 'menu_style.dart';

// Examples can assume:
// late Widget child;

/// A data class that [MenuBarTheme] uses to define the visual properties of
/// [MenuBar] widgets.
///
/// This class defines the visual properties of [MenuBar] widgets themselves,
/// but not their submenus. Those properties are defined by [MenuThemeData] or
/// [MenuButtonThemeData] instead.
///
/// Descendant widgets obtain the current [CustomMenuBarThemeData] object using
/// `MenuBarTheme.of(context)`.
///
/// Typically, a [CustomMenuBarThemeData] is specified as part of the overall [Theme]
/// with [ThemeData.menuBarTheme]. Otherwise, [MenuTheme] can be used to
/// configure its own widget subtree.
///
/// All [CustomMenuBarThemeData] properties are `null` by default. If any of these
/// properties are null, the menu bar will provide its own defaults.
///
/// See also:
///
/// * [MenuThemeData], which describes the theme for the submenus of a
///   [MenuBar].
/// * [MenuButtonThemeData], which describes the theme for the [MenuItemButton]s
///   in a menu.
/// * [ThemeData], which describes the overall theme for the application.
@immutable
class CustomMenuBarThemeData extends CustomMenuThemeData {
  /// Creates a const set of properties used to configure [MenuTheme].
  const CustomMenuBarThemeData({super.style});

  /// Linearly interpolate between two text button themes.
  static CustomMenuBarThemeData? lerp(
      CustomMenuBarThemeData? a, CustomMenuBarThemeData? b, double t) {
    return CustomMenuBarThemeData(
        style: CustomMenuStyle.lerp(a?.style, b?.style, t));
  }
}

/// An inherited widget that defines the configuration for the [MenuBar] widgets
/// in this widget's descendants.
///
/// This class defines the visual properties of [MenuBar] widgets themselves,
/// but not their submenus. Those properties are defined by [MenuTheme] or
/// [MenuButtonTheme] instead.
///
/// Values specified here are used for [MenuBar]'s properties that are not given
/// an explicit non-null value.
///
/// See also:
/// * [MenuStyle], a configuration object that holds attributes of a menu, and
///   is used by this theme to define those attributes.
/// * [MenuTheme], which does the same thing for the menus created by a
///   [SubmenuButton] or [MenuAnchor].
/// * [MenuButtonTheme], which does the same thing for the [MenuItemButton]s
///   inside of the menus.
/// * [SubmenuButton], a button that manages a submenu that uses these
///   properties.
/// * [MenuBar], a widget that creates a menu bar that can use [SubmenuButton]s.
class MenuBarTheme extends InheritedTheme {
  /// Creates a theme that controls the configurations for [MenuBar] and
  /// [MenuItemButton] in its widget subtree.
  const MenuBarTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The properties to set for [MenuBar] in this widget's descendants.
  final CustomMenuBarThemeData data;

  /// Returns the closest instance of this class's [data] value that encloses
  /// the given context. If there is no ancestor, it returns
  /// [ThemeData.menuBarTheme].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return MenuTheme(
  ///     data: const MenuThemeData(
  ///       style: MenuStyle(
  ///         backgroundColor: WidgetStatePropertyAll<Color?>(Colors.red),
  ///       ),
  ///     ),
  ///     child: child,
  ///   );
  /// }
  /// ```
  static CustomMenuBarThemeData of(BuildContext context) {
    final MenuBarTheme? menuBarTheme =
        context.dependOnInheritedWidgetOfExactType<MenuBarTheme>();
    return menuBarTheme?.data ?? const CustomMenuBarThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MenuBarTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(MenuBarTheme oldWidget) => data != oldWidget.data;
}
