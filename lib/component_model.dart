import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:flutter_builder/cubit/component_property/component_property_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:flutter_builder/parameter_model.dart';
import 'package:provider/provider.dart';

abstract class Component {
  final List<Parameter> parameters;
  final String name;
  Component? parent;
  Rect? boundary;

  Component(this.name, this.parameters);

  Widget build(BuildContext context) {
    return BlocBuilder<ComponentCreationCubit, ComponentCreationState>(
      builder: (context, state) {
        print('BUILDING $name');
        WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
          final RenderBox renderBox = GlobalObjectKey(this)
              .currentContext!
              .findRenderObject()! as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero,
              ancestor: const GlobalObjectKey('device window')
                  .currentContext!
                  .findRenderObject());

          boundary = Rect.fromLTWH(position.dx - 1, position.dy - 1,
              renderBox.size.width, renderBox.size.height);
          if (Provider
              .of<ComponentSelectionCubit>(context, listen: false)
              .currentSelected ==
              this) {
            Provider.of<VisualBoxCubit>(context, listen: false).visualUpdated();
          }
        });
        return create(context);
      },
      key: GlobalObjectKey(this),
      buildWhen: (state1, state2) {
        switch (state2.runtimeType) {
          case ComponentPropertyChangeState :
            if ((state2 as ComponentPropertyChangeState).rebuildComponent
                .parent == parent) {
              return true;
            }
            break;
         case
        }
        return false;
      },
    );
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
    return '$name(\n$middle),';
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
      childrenCode += comp.code();
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

  @override
  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      Component? component;
      for (final child in children) {
        if ((component = child.searchTappedComponent(offset)) != null) {
          return component!.searchTappedComponent(offset);
        }
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
}

abstract class Holder extends Component {
  Component? child;
  bool required;

  Holder(String name, List<Parameter> parameters, {this.required = false})
      : super(name, parameters);

  void updateChild(Component? child) {
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
        return '$name(\n${middle}child:Container(),\n),';
      }
    }
    return '$name(\n${middle}child:${child!.code()}\n),';
  }
}

abstract class CustomNamedHolder extends Component {
  Map<String, Component?> children = {};
  late Map<String, List<String>?> selectable;

  CustomNamedHolder(String name, List<Parameter> parameters, this.selectable)
      : super(name, parameters) {
    for (final child in selectable.keys) {
      children[child] = null;
    }
  }

  void updateChild(String key, Component? component) {
    children[key] = component;
    component?.setParent(this);
  }

  @override
  Component? searchTappedComponent(Offset offset) {
    if (boundary?.contains(offset) ?? false) {
      Component? component;
      for (final child in children.values) {
        if (child == null) {
          continue;
        }
        if ((component = child.searchTappedComponent(offset)) != null) {
          return component!.searchTappedComponent(offset);
        }
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
    for (final child in children.keys) {
      if (children[child] != null) {
        childrenCode += '$child:${children[child]!.code()}';
      }
    }
    return '$name(\n$middle$childrenCode\n),';
  }
}
