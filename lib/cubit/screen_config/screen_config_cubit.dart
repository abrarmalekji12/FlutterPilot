import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:fvb_processor/compiler/code_processor.dart';

import '../../collections/project_info_collection.dart';
import '../../injector.dart';
import '../../screen_model.dart';

part 'screen_config_state.dart';

final List<ScreenConfig> defaultScreenConfigs = [
  ScreenConfig('iPhone X', 375, 812, TargetPlatformType.mobile),
  ScreenConfig('iPhone 12/13 Pro', 390, 844, TargetPlatformType.mobile),
  ScreenConfig('Pixel 6 Pro', 360, 780, TargetPlatformType.mobile),
  ScreenConfig('iPhone 13 Mini/11 Pro', 375, 812, TargetPlatformType.mobile),
  ScreenConfig('iPhone 5/SE', 320, 568, TargetPlatformType.mobile),
  ScreenConfig('iPad Pro 11', 834, 1194, TargetPlatformType.tablet),
  ScreenConfig('Galaxy Tab S7', 800, 1280, TargetPlatformType.tablet),
  ScreenConfig('Macbook Air', 1280, 800, TargetPlatformType.desktop, scale: 2),
  ScreenConfig('Macbook Pro', 1728, 1085, TargetPlatformType.desktop,
      scale: 1.25),
  ScreenConfig('Laptop (15")', 1920, 1080, TargetPlatformType.desktop,
      scale: 1.25),
];
ScreenConfig? selectedConfig;

class ScreenConfigCubit extends Cubit<ScreenConfigState> {
  final UserProjectCollection collection;

  List<ScreenConfig> get screenConfigs => defaultScreenConfigs
      .where((element) =>
          collection.project!.settings.target[element.type] ?? true)
      .toList(growable: false);
  ScreenConfigCubit(this.collection) : super(ScreenConfigInitial());

  void applyCurrentSizeToVariables() {
    final processor = sl<Processor>(instanceName: 'system');
    processor.variables['dw']!.setValue(processor, selectedConfig?.width);
    processor.variables['dh']!.setValue(processor, selectedConfig?.height);
  }

  Offset getSelectedConfig(BoxConstraints constraints) {
    final widthScale = selectedConfig!.width / constraints.maxWidth;
    final heightScale = selectedConfig!.height / constraints.maxHeight;
    if (widthScale > 1 && heightScale > 1) {
      if (selectedConfig!.height > selectedConfig!.width) {
        return Offset(
            selectedConfig!.width *
                (constraints.maxHeight /
                    (selectedConfig!.height * constraints.maxWidth)),
            1);
      }
      return Offset(
          1,
          selectedConfig!.height *
              (constraints.maxWidth /
                  (constraints.maxHeight * selectedConfig!.width)));
    } else if (widthScale > 1) {
      return Offset(1, constraints.maxHeight * heightScale);
    } else if (heightScale > 1) {
      return Offset(constraints.maxWidth * widthScale, 1);
    }
    return Offset(widthScale, heightScale);
  }

  void changeScreenConfig(ScreenConfig config) {
    selectedConfig = config;
    final processor = sl<Processor>(instanceName: 'system');
    processor.variables['dw']!.setValue(processor, selectedConfig!.width);
    processor.variables['dh']!.setValue(processor, selectedConfig!.height);
    emit(ScreenConfigChangeState());
  }
}
