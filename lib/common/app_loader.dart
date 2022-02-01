import 'package:flutter/cupertino.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';

abstract class AppLoader{
  static void show(BuildContext context){
      Loader.show(context);
  }
  static void hide(){
    Loader.hide();
  }
}