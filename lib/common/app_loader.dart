import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';

import '../constant/app_colors.dart';

enum LoadingMode { defaultMode, projectLoadingMode }

abstract class AppLoader {
  static bool isShowing=false;
  static void show(BuildContext context,
      {LoadingMode loadingMode = LoadingMode.defaultMode}) {
    isShowing=true;
    Loader.show(context,
        progressIndicator: loadingMode != LoadingMode.defaultMode
            ? getProgressIndicator(loadingMode)
            : null);
  }

  static Widget getProgressIndicator(LoadingMode mode) {
    switch (mode) {
      case LoadingMode.defaultMode:
        break;
      case LoadingMode.projectLoadingMode:
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xfff2f2f2),
                borderRadius: BorderRadius.circular(10)),
            child: const Text(
              'Loading project, please wait..',
              style: TextStyle(
                  color: AppColors.theme,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'arial',
                  fontSize: 18),
            ),
          ),
        );
    }
    return Container();
  }

  static void hide() {
    if(isShowing) {
      Loader.hide();
      isShowing=false;
    }
  }
}
