// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Examples can assume:
// late BuildContext context;

/// A [ButtonStyle] theme that overrides the default appearance of
/// [SubmenuButton]s and [MenuItemButton]s when it's used with a
/// [CustomMenuButtonTheme] or with the overall [Theme]'s [ThemeData.menuTheme].
///
/// The [style]'s properties override [MenuItemButton]'s and [SubmenuButton]'s
/// default style, i.e. the [ButtonStyle] returned by
/// [MenuItemButton.defaultStyleOf] and [SubmenuButton.defaultStyleOf]. Only the
/// style's non-null property values or resolved non-null
/// [WidgetStateProperty] values are used.
///
/// See also:
///
/// * [CustomMenuButtonTheme], the theme which is configured with this class.
/// * [MenuTheme], the theme used to configure the look of the menus these
///   buttons reside in.
/// * [MenuItemButton.defaultStyleOf] and [SubmenuButton.defaultStyleOf] which
///   return the default [ButtonStyle]s for menu buttons.
/// * [MenuItemButton.styleFrom] and [SubmenuButton.styleFrom], which converts
///   simple values into a [ButtonStyle] that's consistent with their respective
///   defaults.
/// * [WidgetStateProperty.resolve], "resolve" a material state property to a
///   simple value based on a set of [WidgetState]s.
/// * [ThemeData.menuButtonTheme], which can be used to override the default
///   [ButtonStyle] for [MenuItemButton]s and [SubmenuButton]s below the overall
///   [Theme].
/// * [MenuAnchor], a widget which hosts cascading menus.
/// * [MenuBar], a widget which defines a menu bar of buttons hosting cascading
///   menus.
@immutable
class CustomMenuButtonThemeData with Diagnosticable {
  /// Creates a [CustomMenuButtonThemeData].
  ///
  /// The [style] may be null.
  const CustomMenuButtonThemeData({this.style});

  /// Overrides for [SubmenuButton] and [MenuItemButton]'s default style.
  ///
  /// Non-null properties or non-null resolved [WidgetStateProperty] values
  /// override the [ButtonStyle] returned by [SubmenuButton.defaultStyleOf] or
  /// [MenuItemButton.defaultStyleOf].
  ///
  /// If [style] is null, then this theme doesn't override anything.
  final ButtonStyle? style;

  /// Linearly interpolate between two menu button themes.
  static CustomMenuButtonThemeData? lerp(
      CustomMenuButtonThemeData? a, CustomMenuButtonThemeData? b, double t) {
    return CustomMenuButtonThemeData(
        style: ButtonStyle.lerp(a?.style, b?.style, t));
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
    return other is CustomMenuButtonThemeData && other.style == style;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

/// Overrides the default [ButtonStyle] of its [MenuItemButton] and
/// [SubmenuButton] descendants.
///
/// See also:
///
/// * [CustomMenuButtonThemeData], which is used to configure this theme.
/// * [MenuTheme], the theme used to configure the look of the menus themselves.
/// * [MenuItemButton.defaultStyleOf] and [SubmenuButton.defaultStyleOf] which
///   return the default [ButtonStyle]s for menu buttons.
/// * [MenuItemButton.styleFrom] and [SubmenuButton.styleFrom], which converts
///   simple values into a [ButtonStyle] that's consistent with their respective
///   defaults.
/// * [ThemeData.menuButtonTheme], which can be used to override the default
///   [ButtonStyle] for [MenuItemButton]s and [SubmenuButton]s below the overall
///   [Theme].
class CustomMenuButtonTheme extends InheritedTheme {
  /// Create a [CustomMenuButtonTheme].
  ///
  /// The [data] parameter must not be null.
  const CustomMenuButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The configuration of this theme.
  final CustomMenuButtonThemeData data;

  /// The closest instance of this class that encloses the given context.
  ///
  /// If there is no enclosing [CustomMenuButtonTheme] widget, then
  /// [ThemeData.menuButtonTheme] is used.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MenuButtonThemeData theme = MenuButtonTheme.of(context);
  /// ```
  static CustomMenuButtonThemeData of(BuildContext context) {
    final CustomMenuButtonTheme? buttonTheme =
        context.dependOnInheritedWidgetOfExactType<CustomMenuButtonTheme>();
    return buttonTheme?.data ?? const CustomMenuButtonThemeData();
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CustomMenuButtonTheme(data: data, child: child);
  }

  @override
  bool updateShouldNotify(CustomMenuButtonTheme oldWidget) =>
      data != oldWidget.data;
}
