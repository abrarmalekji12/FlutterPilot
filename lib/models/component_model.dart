import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/code_to_component.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/models/parameter_info.dart';
import 'package:flutter_builder/models/parameter_model.dart';

import '../component_list.dart';

class MainExecution {
  Component? rootComponent;
  List<CustomComponent> customComponents = [];

  MainExecution() {
    final homePage = StatelessComponent(
        name: 'HomePage',
        dependencies: [],
        root: Component.fromCode('''
          Container(
          width:150,
          child:Padding(
          padding:EdgeInsets.only(
          bottom:2.5
          ),
          child:Column(
          children:[
          Padding(
          padding:EdgeInsets.all(10.4),
          )
          ]
          ),
          ),
          alignment:Alignment.topRight,
          decoration:BoxDecoration(
          border:Border(
          top:BorderSide(
          color:Color(0xff00ff00),
          width:32.4
          ),
          ),
          ),
          )
          '''
            .replaceAll('\n', '')
            .replaceAll(' ', '')));
    customComponents.add(homePage);
    setRoot(componentList['MaterialApp']!());
    final customCopy = homePage.createInstance(rootComponent);
    (rootComponent as CustomNamedHolder).updateChildWithKey('home', customCopy);
  }

  void setRoot(Component component) {
    rootComponent = component;
    component.setParent(null);
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

  static Component fromCode(String code) {
    final name = code.substring(0, code.indexOf('(', 0));
    final comp = componentList[name]!();

    final componentCode = code.replaceFirst('$name(', '');
    final parameterCodes = CodeToComponent.splitByComma(
        componentCode.substring(0, componentCode.length - 1));

    switch (comp.type) {
      case 3:
        int index = -1;
        for (int i = 0; i < parameterCodes.length; i++) {
          if (parameterCodes[i].startsWith('child:')) {
            index = i;
            break;
          }
        }
        if (index != -1) {
          final childCode = parameterCodes.removeAt(index);
          print('CHILD CODE $childCode');
          (comp as Holder).updateChild(
              Component.fromCode(childCode.replaceFirst('child:', '')));
        }
        break;
      case 2:
        int index = -1;
        for (int i = 0; i < parameterCodes.length; i++) {
          if (parameterCodes[i].startsWith('children:')) {
            index = i;
            break;
          }
        }
        if (index != -1) {
          final childCode = parameterCodes.removeAt(index);
          print('CHILD CODE $childCode');
          final code2 = childCode.replaceFirst('children:[', '');
          final List<Component> componentList = [];
          final List<String> childrenCodes = CodeToComponent.splitByComma(
              code2.substring(0, code2.length - 1));
          for (final childCode in childrenCodes) {
            componentList.add(Component.fromCode(childCode)..setParent(comp));
          }
          (comp as MultiHolder).children = componentList;
        }
        break;
      case 4:
        break;
      case 1:
        break;
    }
    for (Parameter parameter in comp.parameters) {
      if (parameter.info is NamedParameterInfo ||
          (parameter.info is InnerObjectParameterInfo &&
              (parameter.info as InnerObjectParameterInfo).namedIfHaveAny !=
                  null)) {
        for (final paramCode in parameterCodes) {
          if (paramCode.startsWith(
              '${parameter.info is NamedParameterInfo ? (parameter.info as NamedParameterInfo).name : (parameter.info as InnerObjectParameterInfo).namedIfHaveAny!}:')) {
            parameter.fromCode(paramCode);
            break;
          }
        }
      }
    }
    return comp;
  }

  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      _lookForUIChanges(context);
    });

    return ComponentWidget(key: GlobalObjectKey(this), child: create(context));
  }

  void _lookForUIChanges(BuildContext context) async {
    final RenderBox renderBox =
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
      if ((boundary?.left??position.dx) - position.dx < 0.5 &&
          (boundary?.top??position.dy) - position.dy < 0.5&&
          (boundary?.width??renderBox.size.width) - renderBox.size.width < 0.5&&
          (boundary?.height??renderBox.size.height) - renderBox.size.height < 0.5) {
        sameCount++;
      }
      boundary = Rect.fromLTWH(position.dx, position.dy, renderBox.size.width,
          renderBox.size.height);
      depth = renderBox.depth;
      BlocProvider.of<VisualBoxCubit>(context, listen: false).visualUpdated();
      print(
          '======== COMPONENT VISUAL BOX CHANGED  ${boundary?.width} ${renderBox.size.width} ${boundary?.height} ${renderBox.size.height}');
      await Future.delayed(const Duration(milliseconds: 50));
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
      childrenCode += '${comp.code()},'.replaceAll(',,', ',');
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
    component.setParent(this);
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
  CustomComponent? cloneOf;
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
    return root?.build(context) ?? Container();
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
      Component? tracer=objects[i];
      while(tracer!.parent!=null){
        print('======= TRACER FIND ROOT ${tracer.parent?.name}');
        tracer=tracer.parent;
      }
      if(tracer is CustomComponent){
        tracer.notifyChanged();
      }
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

  CustomComponent createInstance(Component? root) {
    final customCopy = clone(root);
    objects.add(customCopy as CustomComponent);
    customCopy.cloneOf = this;
    return customCopy;
  }

  Component findSameLevelComponent(
      CustomComponent copy, CustomComponent original, Component object) {
    Component? tracer = object;
    final List<List<Parameter>> paramList = [];
    print('FIND FIRST LEVEL');
    while (tracer != original) {
      print('TRACER ${tracer?.name}');
      paramList.add(tracer!.parameters);
      tracer = tracer.parent;
    }
    // print('TRACER 1 ${tracer?.name}');
    tracer = copy;
    for (final param in paramList.reversed) {
      tracer = findChildWithParam(tracer!, param);
    }
    // print('TRACER 2 ${tracer?.name}');

    return tracer!;
  }

  Component? findChildWithParam(Component component, List<Parameter> params) {
    switch (component.type) {
      case 3:
        return (component as Holder).child!;
      case 2:
        return (component as MultiHolder)
            .children
            .firstWhere((element) => element.parameters == params);
      case 4:
        return (component as CustomNamedHolder).childMap.values.firstWhere(
            (element) => element != null && element.parameters == params);
      case 5:
        return (component as CustomComponent).root;
    }
    return null;
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
