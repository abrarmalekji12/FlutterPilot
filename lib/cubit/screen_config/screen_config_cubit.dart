import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/common/logger.dart';
import 'package:meta/meta.dart';

import '../../screen_model.dart';

part 'screen_config_state.dart';

class ScreenConfigCubit extends Cubit<ScreenConfigState> {
  final List<ScreenConfig> screenConfigs = [

    ScreenConfig('iPad Pro', 1024, 1366),
    ScreenConfig('iPhone 11 Pro', 1125,2436),
    ScreenConfig('iPad Pro', 2560, 1600),
    ScreenConfig('iPhone 6', 375, 667),
    ScreenConfig('iPhone SE', 320, 568),
  ];

  late ScreenConfig screenConfig;

  ScreenConfigCubit() : super(ScreenConfigInitial()){
    screenConfig=screenConfigs[0];
  }
  
  Offset getSelectedConfig(BoxConstraints constraints){
    final widthScale=screenConfig.width/constraints.maxWidth;
    final heightScale=screenConfig.height/constraints.maxHeight;
    if(widthScale>1&&heightScale>1){
     if(screenConfig.height>screenConfig.width) {
       return Offset(screenConfig.width*(constraints.maxHeight/(screenConfig.height*constraints.maxWidth)),1);
     }
     return Offset(1, screenConfig.height*(constraints.maxWidth/(constraints.maxHeight*screenConfig.width)));
    }
    if(widthScale>1){
      return  Offset(1,constraints.maxHeight * heightScale);
    }
    if(heightScale>1){
      return  Offset(constraints.maxWidth * widthScale,1);
    }
    return  Offset(widthScale, heightScale);

  }

  void changeScreenConfig(ScreenConfig config) {
    screenConfig = config;
    emit(ScreenConfigChangeState());
  }
}
