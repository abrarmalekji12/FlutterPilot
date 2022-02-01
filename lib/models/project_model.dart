import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_builder/models/other_model.dart';

import '../common/logger.dart';
import '../component_list.dart';

import 'component_model.dart';

class FlutterProject {
  String name;
  final List<CustomComponent> customComponents = [];
  Component? rootComponent;

  final List<FavouriteModel> favouriteList=[];

  FlutterProject(this.name);

  factory FlutterProject.createNewProject(String name) {
    final FlutterProject flutterProject = FlutterProject(name);
    flutterProject.rootComponent = componentList['MaterialApp']!();
    return flutterProject;
  }

  String code() {
    String implementationCode = '';
    if (customComponents.isNotEmpty) {
      for (final customComponent in customComponents) {
        implementationCode += '${customComponent.implementationCode()}\n';
      }
    }
    logger('IMPL $implementationCode');
    return ''' 
    void main(){
    runApp(${rootComponent!.code()});
    } 
    $implementationCode
    ''';
  }

  Widget run(BuildContext context) {
    return rootComponent!.build(context);
  }
  void setRoot(Component component) {
    rootComponent = component;
    component.setParent(null);
  }

}


class ProjectGroup {
  List<FlutterProject> projects=[];

}
