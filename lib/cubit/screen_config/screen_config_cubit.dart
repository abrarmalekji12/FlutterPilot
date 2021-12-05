import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

import '../../screen_model.dart';

part 'screen_config_state.dart';

class ScreenConfigCubit extends Cubit<ScreenConfigState> {
  final List<ScreenConfig> screenConfigs = [
    ScreenConfig('iPad Pro', 2560, 1600),
    ScreenConfig('iPhone 6', 375, 667),
    ScreenConfig('iPhone SE', 320, 568),
    ScreenConfig('iPad Pro', 1024, 1366),
  ];

  late ScreenConfig screenConfig;

  ScreenConfigCubit() : super(ScreenConfigInitial()){
    screenConfig=screenConfigs[0];
  }
  
  double getSelectedConfig(BoxConstraints constraints){
    if(screenConfig.width<constraints.maxWidth&&screenConfig.height<constraints.maxHeight){
      screenConfig.scale=1;
    }
    else if(screenConfig.width<screenConfig.height){
      screenConfig.scale=1;
    }
    else {
      screenConfig.scale=0.9;
    }
    print('scale ${screenConfig.scale}');
    return  screenConfig.scale!;

  }

  void changeScreenConfig(ScreenConfig config) {
    screenConfig = config;
    emit(ScreenConfigChangeState());
  }
}
