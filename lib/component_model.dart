import 'package:flutter/material.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/parameter_model.dart';
import 'package:flutter_builder/ui/home_page.dart';
import 'package:provider/provider.dart';

import 'component_list.dart';

class MainExecution {
  Component? rootComponent;
  List<CustomComponent> customComponents = [];

  MainExecution() {
    final homePage=StatelessComponent(
        name: 'HomePage',
        dependencies: [],
        root: componentList['Scaffold']!());
    customComponents.add(homePage);
    setRoot(componentList['MaterialApp']!());
    final customCopy= homePage.clone(rootComponent);
    homePage.objects.add(customCopy as CustomComponent);
    (rootComponent as CustomNamedHolder)
        .updateChildWithKey('home',customCopy);
  }

  void setRoot(Component component) {
    rootComponent = component;
    component.setParent(rootComponent);
  }

  String code() {
    String implementationCode = '';
    if (customComponents.isNotEmpty) {
      for (final customComponent in customComponents) {
        implementationCode += '${customComponent.implementationCode()}\n';
      }
    }
    print('IMPL $implementationCode');
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
}

abstract class Component {
  List<Parameter> parameters;
  String name;
  bool isConstant;
  Component? parent;
  Rect? boundary;
  int? depth;

  Component(this.name, this.parameters, {this.isConstant = false});

  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _lookForUIChanges(context);
    });

    return ComponentWidget(key: GlobalObjectKey(this), child: create(context));
  }

  void _lookForUIChanges(BuildContext context) async {
    RenderBox renderBox =
        GlobalObjectKey(this).currentContext!.findRenderObject()! as RenderBox;
    Offset position = renderBox.localToGlobal(Offset.zero,
        ancestor: const GlobalObjectKey('device window')
            .currentContext!
            .findRenderObject());
    final ancestor = const GlobalObjectKey('device window')
        .currentContext!
        .findRenderObject();
    int sameCount = 0;
    while (sameCount < 5) {
      if (boundary?.left == position.dx &&
          boundary?.top == position.dy &&
          boundary?.width == renderBox.size.width &&
          boundary?.height == renderBox.size.height) {
        sameCount++;
      }
      boundary = Rect.fromLTWH(position.dx, position.dy, renderBox.size.width,
          renderBox.size.height);
      depth = renderBox.depth;
      // if (Provider.of<ComponentSelectionCubit>(context, listen: false)
      //         .currentSelected ==
      //     this) {
        Provider.of<VisualBoxCubit>(context, listen: false).visualUpdated();
      // }
      await Future.delayed(const Duration(milliseconds: 50));
      renderBox = GlobalObjectKey(this).currentContext!.findRenderObject()!
          as RenderBox;
      position = renderBox.localToGlobal(Offset.zero, ancestor: ancestor);
    }
  }

  Widget create(BuildContext context);

  String code() {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code;
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
      }
    }
    middle = middle.replaceAll(',', ',\n');
    if (middle.trim().isEmpty) {
      return '$name()';
    }
    return '$name(\n$middle)';
  }

  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      return this;
    }
    return null;
  }

  void setParent(Component? component) {
    parent = component;
  }

  Component clone(Component? parent) {
    final comp = componentList[name]!();
    comp.parameters = parameters;
    comp.parent = parent;
    return comp;
  }

  int get type => 1;

  int get childCount => 0;
}

abstract class MultiHolder extends Component {
  List<Component> children = [];

  MultiHolder(String name, List<Parameter> parameters)
      : super(name, parameters);

  @override
  String code() {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code;
      if (paramCode.isNotEmpty) {
        middle += '$paramCode,'.replaceAll(',,', ',');
      }
    }
    middle = middle.replaceAll(',', ',\n');
    String childrenCode = '';
    for (final Component comp in children) {
      childrenCode += '${comp.code()},';
    }
    return '$name(\n${middle}children:[\n$childrenCode\n],\n)';
  }

  void addChild(Component component, {int? index}) {
    if (index == null) {
      children.add(component);
    } else {
      children.insert(index, component);
    }
    component.setParent(this);
  }

  int removeChild(Component component) {
    final index = children.indexOf(component);
    component.setParent(null);
    children.remove(component);
    return index;
  }

  void replaceChild(Component old, Component component) {
    final index = children.indexOf(old);
    children.remove(old);
    children.insert(index, component);
    component.parent = this;
  }

  @override
  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      Component? component;
      Component? depthComponent;
      for (final child in children) {
        if ((depthComponent == null ||
                component!.depth! > depthComponent.depth!) &&
            (component = child.searchTappedComponent(offset)) != null) {
          depthComponent = component;
        }
      }
      if (depthComponent != null) {
        return depthComponent.searchTappedComponent(offset);
      }
      return this;
    }
  }

  void addChildren(List<Component> components) {
    children.addAll(components);
    for (final comp in components) {
      comp.setParent(this);
    }
  }

  @override
  Component clone(Component? parent) {
    final comp = componentList[name]!() as MultiHolder;
    comp.parameters = parameters;
    comp.parent = parent;
    comp.children = children.map((e) => e.clone(comp)).toList();
    return comp;
  }

  @override
  int get type => 2;

  @override
  int get childCount => -1;
}

abstract class Holder extends Component {
  Component? child;
  bool required;

  Holder(String name, List<Parameter> parameters, {this.required = false})
      : super(name, parameters);

  void updateChild(Component? child) {
    this.child?.setParent(null);
    this.child = child;
    if (child != null) {
      child.setParent(this);
    }
  }

  @override
  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      Component? component;
      if ((component = child?.searchTappedComponent(offset)) != null) {
        return component;
      }
      return this;
    }
  }

  @override
  String code() {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code;
      if (paramCode.isNotEmpty) {
        final paramCode = para.code;
        if (paramCode.isNotEmpty) {
          middle += '$paramCode,'.replaceAll(',,', ',');
        }
      }
    }
    middle = middle.replaceAll(',', ',\n');
    if (child == null) {
      if (!required) {
        return '$name(\n$middle\n),';
      } else {
        return '$name(\n${middle}child:Container(),\n)';
      }
    }
    return '$name(\n${middle}child:${child!.code()}\n)';
  }

  @override
  Component clone(Component? parent) {
    final comp = componentList[name]!() as Holder;
    comp.parameters = parameters;
    comp.parent = parent;
    comp.child = child?.clone(comp);
    return comp;
  }

  @override
  // TODO: implement type
  int get type => 3;

  @override
  int get childCount => 1;
}

abstract class CustomNamedHolder extends Component {
  Map<String, Component?> childMap = {};
  Map<String, List<Component>> childrenMap = {};

  late Map<String, List<String>?> selectable;

  CustomNamedHolder(String name, List<Parameter> parameters, this.selectable,
      List<String> childrenMap)
      : super(name, parameters) {
    for (final child in selectable.keys) {
      childMap[child] = null;
    }
    for (final children in childrenMap) {
      this.childrenMap[children] = [];
    }
  }

  void updateChildWithKey(String key, Component? component) {
    childMap[key]?.setParent(null);
    childMap[key] = component;
    component?.setParent(this);
  }

  void updateChild(Component? oldComponent, Component? component) {
    oldComponent?.setParent(null);
    component?.setParent(this);
    for (final entry in childMap.entries) {
      if (entry.value == oldComponent) {
        childMap[entry.key] = component;
        return;
      }
    }

  }

  @override
  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      Component? component, depthComponent;
      for (final child in childMap.values) {
        if (child == null) {
          continue;
        }
        if ((depthComponent == null ||
                component!.depth! > depthComponent.depth!) &&
            (component = child.searchTappedComponent(offset)) != null) {
          depthComponent = component;
        }
      }
      if (depthComponent != null) {
        return depthComponent.searchTappedComponent(offset);
      }
      return this;
    }
  }

  @override
  String code() {
    String middle = '';
    for (final para in parameters) {
      final paramCode = para.code;
      if (paramCode.isNotEmpty) {
        final paramCode = para.code;
        if (paramCode.isNotEmpty) {
          middle += '$paramCode,'.replaceAll(',,', ',');
        }
      }
    }
    middle = middle.replaceAll(',', ',\n');

    String childrenCode = '';
    for (final child in childMap.keys) {
      if (childMap[child] != null) {
        childrenCode += '$child:${childMap[child]!.code()},';
      }
    }
    return '$name(\n$middle$childrenCode\n)';
  }

  @override
  Component clone(Component? parent) {
    final comp = componentList[name]!() as CustomNamedHolder;
    comp.parameters = parameters;
    comp.parent = parent;
    comp.childMap =
        childMap.map((key, value) => MapEntry(key, value?.clone(comp)));
    comp.childrenMap = childrenMap.map((key, value) =>
        MapEntry(key, value.map((e) => e.clone(comp)).toList()));
    return comp;
  }

  @override
  int get type => 4;

  String? replaceChild(Component oldComp, Component? comp) {
    late final String? compKey;
    for (final String key in childMap.keys) {
      if (childMap[key] == oldComp) {
        compKey = key;
        break;
      }
    }
    if (compKey != null) {
      childMap[compKey] = comp;
      comp?.setParent(this);
      return compKey;
    }
  }

  @override
  int get childCount => -2;
}

abstract class CustomComponent extends Component {
  String? extensionName;
  Component? root;
  List<CustomComponent> objects = [];
  List<CustomComponent> dependencies = [];

  CustomComponent(
      {required this.extensionName,
      required this.dependencies,
      required String name,
      this.root})
      : super(name, []);

  @override
  Widget create(BuildContext context) {
    return root?.build(context) ??Container();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _lookForUIChanges(context);
    });
    return ComponentWidget(key: GlobalObjectKey(this), child: create(context));
  }

  @override
  Component? searchTappedComponent(Offset offset) {
    if (root?.boundary?.contains(offset) ?? false) {
      return root?.searchTappedComponent(offset) ?? this;
    }
  }

  void notifyChanged() {
    for (int i = 0; i < objects.length; i++) {
      final oldObject = objects[i];
      objects[i] = clone(objects[i].parent) as CustomComponent;
      replaceChildOfParent(oldObject, objects[i]);
    }
  }

  void replaceChildOfParent(Component comOld, Component comp) {
    switch (comOld.parent?.type) {
      case 2:
        //MultiHolder
        (comOld.parent as MultiHolder).replaceChild(comOld, comp);
        break;
      case 3:
        //Holder
        (comOld.parent as Holder).updateChild(comp);
        break;
      case 4:
        //CustomNamedHolder
        (comOld.parent as CustomNamedHolder).replaceChild(comOld, comp);
        break;
      case 5:
        (comOld.parent as CustomComponent).root = comp;
    }
  }

  String implementationCode();

  @override
  int get type => 5;

  @override
  int get childCount => 0;

  @override
  Component clone(Component? parent) {
    final comp2 = StatelessComponent(name: name, dependencies: dependencies);
    comp2.name = name;
    comp2.parameters = parameters;
    comp2.root = root?.clone(parent);
    return comp2;
  }
}

class StatelessComponent extends CustomComponent {
  StatelessComponent(
      {required String name,
      required List<CustomComponent> dependencies,
      Component? root})
      : super(
            extensionName: 'StatelessWidget',
            dependencies: dependencies,
            name: name,
            root: root) {
    if (root != null) {
      root.setParent(this);
    }
  }

  @override
  String implementationCode() {
    return '''class $name extends StatelessWidget {
          const $name({Key? key}) : super(key: key);
        
          @override
          Widget build(BuildContext context) {
          return ${root!.code()};
          }
         }
    ''';
  }
}

class ComponentWidget extends StatelessWidget {
  final Widget child;

  const ComponentWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
