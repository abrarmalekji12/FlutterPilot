import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/parameter_model.dart';
import 'package:provider/provider.dart';

abstract class Component {
  final List<Parameter> parameters;
  final String name;
  Component? parent;

  Component(this.name, this.parameters);

  Widget build(BuildContext context){
    return BlocBuilder<ComponentPropertyCubit,ComponentPropertyState>(builder: (context,state){
      return create(context);
    },
      buildWhen: (state1,state2){
      if(Provider.of<ComponentSelectionCubit>(context,listen: false).currentSelected==this) {
        return true;
      }
      return false;
      },

    );
  }
  Widget create(BuildContext context);

  String code() {
    String middle='';
    for(final para in parameters){
      final paramCode=para.code;
      if(paramCode.isNotEmpty) {
        middle+= '$paramCode,'.replaceAll(',,', ',');
      }
    }
    middle=middle.replaceAll(',', ',\n');
    return '$name(\n$middle),';
  }

  void setParent(Component? component) {
    parent = component;
  }
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters)
      : super(name, parameters);

  @override
  String code() {
    String middle='';
    for(final para in parameters){
      final paramCode=para.code;
      if(paramCode.isNotEmpty) {
        middle+= '$paramCode,'.replaceAll(',,', ',');
      }
    }
    middle=middle.replaceAll(',', ',\n');
    String childrenCode='';
    for(final Component comp in children){
      childrenCode+=comp.code();
    }
    return '$name(\n${middle}children:[\n$childrenCode\n],\n),';
  }
  void addChild(Component component) {
    children.add(component);
    component.setParent(this);
  }
  void removeChild(Component component) {

    component.setParent(null);
    children.remove(component);
  }

  void addChildren(List<Component> components) {
    children.addAll(components);
    for(final comp in components){
      comp.setParent(this);
    }
  }
}

abstract class Holder extends Component {
  Component? child;

  Holder(String name, List<Parameter> parameters) : super(name, parameters);

  void updateChild(Component? child) {
    this.child = child;
    if(child!=null){
      child.setParent(this);
    }
  }

  @override
  String code() {
    String middle='';
    for(final para in parameters){
      final paramCode=para.code;
      if(paramCode.isNotEmpty) {
        final paramCode=para.code;
        if(paramCode.isNotEmpty) {
          middle+= '$paramCode,'.replaceAll(',,', ',');
        }
      }
    }
    middle=middle.replaceAll(',', ',\n');
    if(child==null){
      return '$name(\n$middle\n),';
    }
    return '$name(\n${middle}child:${child!.code()}\n),';
  }
}
abstract class CustomNamedHolder extends Component{
  Map<String,Component?> children={};
  late Map<String,List<String>?> selectable;

  CustomNamedHolder(String name,List<Parameter> parameters,this.selectable) : super(name, parameters){
    for(final child in selectable.keys) {
      children[child]=null;
    }
  }

  void updateChild(String key,Component? component){
    children[key]=component;
  }
  @override
  String code() {
    String middle='';
    for(final para in parameters){
      final paramCode=para.code;
      if(paramCode.isNotEmpty) {
        final paramCode=para.code;
        if(paramCode.isNotEmpty) {
          middle+= '$paramCode,'.replaceAll(',,', ',');
        }
      }
    }
    middle=middle.replaceAll(',', ',\n');

    String childrenCode='';
    for(final child in children.keys){
      if(children[child]!=null){
        childrenCode+='$child:${children[child]!.code()}';
      }
    }
    return '$name(\n$middle$childrenCode\n),';
  }
}
