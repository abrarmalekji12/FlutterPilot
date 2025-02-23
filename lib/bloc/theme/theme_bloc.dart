import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/color_assets.dart';
import '../../constant/preference_key.dart';
import '../../injector.dart';

part 'theme_event.dart';
part 'theme_state.dart';

enum ThemeType {
  light('Light'),
  dark('Dark'),
  highContrast('High Contrast');

  final String name;

  const ThemeType(this.name);

  @override
  String toString() {
    return name;
  }
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeType themeType = ThemeType.light;

  Color get text1Color {
    switch (themeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.dark:
        return Colors.white;
      case ThemeType.highContrast:
        return Colors.white;
    }
  }

  Color get text2Color {
    switch (themeType) {
      case ThemeType.light:
        return ColorAssets.darkGrey;
      case ThemeType.dark:
        return Colors.grey.shade200;
      case ThemeType.highContrast:
        return Colors.grey.shade200;
    }
  }

  Color get text3Color {
    switch (themeType) {
      case ThemeType.light:
        return const Color(0xff494949);
      case ThemeType.dark:
        return const Color(0xffd3d3d3);
      case ThemeType.highContrast:
        return const Color(0xffd3d3d3);
    }
  }

  Color get text4Color {
    switch (themeType) {
      case ThemeType.light:
        return ColorAssets.darkerGrey;
      case ThemeType.dark:
        return ColorAssets.grey;
      case ThemeType.highContrast:
        return ColorAssets.grey;
    }
  }

  Color get hoverColor {
    switch (themeType) {
      case ThemeType.light:
        return const Color(0xffd3d3d3);
      case ThemeType.dark:
        return const Color(0xff989898);
      case ThemeType.highContrast:
        return const Color(0xff989898);
    }
  }

  Color get line {
    switch (themeType) {
      case ThemeType.light:
        return Colors.grey;
      case ThemeType.dark:
        return const Color(0xffd3d3d3);
      case ThemeType.highContrast:
        return const Color(0xffd3d3d3);
    }
  }

  Color get titleColor {
    switch (themeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.dark:
        return Colors.white;
      case ThemeType.highContrast:
        return Colors.white;
    }
  }

  Color get background1 {
    switch (themeType) {
      case ThemeType.light:
        return Colors.white;
      case ThemeType.dark:
        return ColorAssets.black;
      case ThemeType.highContrast:
        return ColorAssets.color262628;
    }
  }

  Color get background2 {
    switch (themeType) {
      case ThemeType.light:
        return ColorAssets.lightGrey;
      case ThemeType.dark:
        return ColorAssets.backgroundDark;
      case ThemeType.highContrast:
        return ColorAssets.black;
    }
  }

  Color get backgroundLightGrey {
    switch (themeType) {
      case ThemeType.light:
        return ColorAssets.lightGrey;
      case ThemeType.dark:
        return ColorAssets.backgroundDark;
      case ThemeType.highContrast:
        return ColorAssets.backgroundDark;
    }
  }

  Color get dropDownColor1 {
    switch (themeType) {
      case ThemeType.light:
        return Colors.grey.shade600;
      case ThemeType.dark:
        return Colors.grey.shade200;
      case ThemeType.highContrast:
        return Colors.grey.shade200;
    }
  }

  Color get dropDownColor2 {
    switch (themeType) {
      case ThemeType.light:
        return Colors.grey.shade700;
      case ThemeType.dark:
        return Colors.grey.shade400;
      case ThemeType.highContrast:
        return Colors.grey.shade400;
    }
  }

  Color get border1 {
    switch (themeType) {
      case ThemeType.light:
        return const Color(0xfff2f2f2);
      case ThemeType.dark:
        return const Color(0xff989898);
      case ThemeType.highContrast:
        return const Color(0xff989898);
    }
  }

  Color get background3 {
    switch (themeType) {
      case ThemeType.light:
        return const Color(0xfff2f2f2);
      case ThemeType.dark:
        return ColorAssets.color262628;
      case ThemeType.highContrast:
        return ColorAssets.color262628;
    }
  }

  Color get iconColor1 {
    switch (themeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.dark:
        return Colors.white;
      case ThemeType.highContrast:
        return Colors.white;
    }
  }

  Color get foregroundColor1 {
    switch (themeType) {
      case ThemeType.light:
        return Colors.black;
      case ThemeType.dark:
        return Colors.grey;
      case ThemeType.highContrast:
        return Colors.white;
    }
  }

  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeEvent>((event, emit) {});
    on<UpdateThemeEvent>(_onThemeUpdate);
    final preference = sl<SharedPreferences>();
    final theme = preference.getString(PrefKey.theme);
    if (theme != null) {
      add(UpdateThemeEvent(
          ThemeType.values.firstWhereOrNull((e) => e.name == theme) ??
              ThemeType.light));
    }
  }

  Future<void> _onThemeUpdate(
      UpdateThemeEvent event, Emitter<ThemeState> emit) async {
    if (event.themeType != themeType) {
      themeType = event.themeType;
      sl<SharedPreferences>().setString(PrefKey.theme, themeType.name);
      emit(ThemeUpdatedState());
    }
  }
}
