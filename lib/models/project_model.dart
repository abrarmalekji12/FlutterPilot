import 'package:flutter/material.dart';
import 'variable_model.dart';
import '../cubit/component_operation/component_operation_cubit.dart';
import 'other_model.dart';
import '../common/logger.dart';
import '../component_list.dart';

import 'component_model.dart';

class FlutterProject {
  String name;
  final int userId;
  final String? device;
  final List<VariableModel> variables=[];
  final List<CustomComponent> customComponents = [];
  Component? rootComponent;
  final List<FavouriteModel> favouriteList = [];

  FlutterProject(this.name,this.userId,{this.device});

  factory FlutterProject.createNewProject(String name,int userId) {
    final FlutterProject flutterProject = FlutterProject(name,userId);
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
    String staticVariablesCode='';
    String dynamicVariablesDefinitionCode='';
    String dynamicVariableAssignmentCode='';
    for(final variable in ComponentOperationCubit.codeProcessor.variables.entries){
      if(!variable.value.runtimeAssigned){
        staticVariablesCode+='static const double ${variable.key} = ${variable.value.value};\n';
      }else{
        dynamicVariablesDefinitionCode+='late double ${variable.key};\n';
        dynamicVariableAssignmentCode+='${variable.key} = ${variable.value.assignmentCode};\n';
      }
    }

    final className=name[0].toUpperCase()+name.substring(1);
    // ${rootComponent!.code()}
    return ''' 
    // copy all the images to assets/images/ folder
    // 
    // TODO Dependencies (add into pubspec.yaml)
    // google_fonts: ^2.2.0
    import 'package:flutter/material.dart';
    import 'package:google_fonts/google_fonts.dart';
    
    void main(){
    runApp(const $className());
    } 
    class $className extends StatefulWidget {
    const $className({Key? key}) : super(key: key);

    @override
   _${className}State createState() => _${className}State();
    }

    class _${className}State extends State<$className> {
     $staticVariablesCode
     $dynamicVariablesDefinitionCode
     @override
     Widget build(BuildContext context) {
         $dynamicVariableAssignmentCode
          return ${rootComponent!.code()};
       } 
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
  List<FlutterProject> projects = [];
}



