import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/common/logger.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/models/variable_model.dart';
import 'package:meta/meta.dart';

import '../../screen_model.dart';

part 'screen_config_state.dart';

class ScreenConfigCubit extends Cubit<ScreenConfigState> {
  final List<ScreenConfig> screenConfigs = [
    ScreenConfig('iPhone X', 375, 812),
    ScreenConfig('iPhone 12/13 Pro', 390, 844),
    ScreenConfig('Pixel 6 Pro', 360, 780),
    ScreenConfig('iPhone 13 Mini/11 Pro', 375, 812),
    ScreenConfig('iPhone 5/SE', 320, 568),
    ScreenConfig('iPad Pro 11', 834, 1194),
    ScreenConfig('Galaxy Tab S7', 800, 1280),
    ScreenConfig('Macbook Air', 1280, 800),
    ScreenConfig('Macbook Pro', 1728, 1085),
    ScreenConfig('Laptop (15")', 1920, 1080),
  ];

  late ScreenConfig screenConfig;

  ScreenConfigCubit() : super(ScreenConfigInitial()) {
    screenConfig = screenConfigs[0];
    ComponentOperationCubit.codeProcessor.variables['dw']=VariableModel('dw',screenConfig.width , true, 'device width',assignmentCode: 'MediaQuery.of(context).size.width',deletable: false);
    ComponentOperationCubit.codeProcessor.variables['dh']=VariableModel('dh',screenConfig.height , true, 'device height',assignmentCode: 'MediaQuery.of(context).size.height',deletable: false);
  }

  Offset getSelectedConfig(BoxConstraints constraints) {
    final widthScale = screenConfig.width / constraints.maxWidth;
    final heightScale = screenConfig.height / constraints.maxHeight;
    if (widthScale > 1 && heightScale > 1) {
      if (screenConfig.height > screenConfig.width) {
        return Offset(
            screenConfig.width *
                (constraints.maxHeight /
                    (screenConfig.height * constraints.maxWidth)),
            1);
      }
      return Offset(
          1,
          screenConfig.height *
              (constraints.maxWidth /
                  (constraints.maxHeight * screenConfig.width)));
    } else if (widthScale > 1) {
      return Offset(1, constraints.maxHeight * heightScale);
    } else if (heightScale > 1) {
      return Offset(constraints.maxWidth * widthScale, 1);
    }
    return Offset(widthScale, heightScale);
  }

  void changeScreenConfig(ScreenConfig config) {
    screenConfig = config;
    ComponentOperationCubit.codeProcessor.variables['dw']!.value=screenConfig.width;
    ComponentOperationCubit.codeProcessor.variables['dh']!.value=screenConfig.height;
    emit(ScreenConfigChangeState());
  }
}
