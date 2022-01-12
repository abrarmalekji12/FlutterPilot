import 'package:flutter/material.dart';

import '../common/logger.dart';
import '../component_list.dart';
import '../firestore/firestore_bridge.dart';

import 'component_model.dart';

class FlutterProject {
  String name;
  final List<CustomComponent> customComponents = [];
  Component? rootComponent;

  FlutterProject(this.name);

  factory FlutterProject.createNewProject() {
    final FlutterProject flutterProject = FlutterProject('untitled1');
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
