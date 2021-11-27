import 'package:flutter/material.dart';
import 'package:flutter_builder/parameter_model.dart';

abstract class Component {
  final List<Parameter> parameters;
  final String name;
  Component? parent;

  Component(this.name, this.parameters);

  Widget create();

  String code();

  void setParent(Component? component) {
    parent = component;
  }
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters)
      : super(name, parameters);

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
}

