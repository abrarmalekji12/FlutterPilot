

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/cubit/component_creation/component_creation_cubit.dart';
import 'package:flutter_builder/cubit/component_selection/component_selection_cubit.dart';
import 'package:flutter_builder/cubit/visual_box_drawer/visual_box_cubit.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

part 'component_operation_state.dart';

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  MainExecution mainExecution;

  ComponentOperationCubit(this.mainExecution)
      : super(ComponentOperationInitial());

  void addedComponent(
      BuildContext context, Component component, Component root) {
    Provider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    Provider.of<ComponentSelectionCubit>(context, listen: false)
        .changeComponentSelection(component, root: root);
    Provider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;

    emit(ComponentUpdatedState());
  }

  void removedComponent(
      BuildContext context, Component component, Component root) {
    Provider.of<ComponentSelectionCubit>(context, listen: false)
        .changeComponentSelection(component, root: root);
    Provider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    Provider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;
    emit(ComponentUpdatedState());
  }

  void arrangeComponent(
    BuildContext context,
  ) {
    Provider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    Provider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;
    emit(ComponentUpdatedState());
  }

  void addCustomComponent(String name, {Component? root}) {
    final component = StatelessComponent(name: name, dependencies: []);
    mainExecution.customComponents.add(component);
    if (root != null) {
      component.root=root;
      final instance=component.createInstance(root.parent);
      // final instance = component.clone(root.parent) as CustomComponent;
      replaceChildOfParent(root, instance);

      root.parent=component;
      // instance.parent=root.parent;
      // component.objects.add(instance);
    }
    emit(ComponentUpdatedState());
  }

  void replaceChildOfParent(Component component, Component comp) {
    switch (component.parent?.type) {
      case 2:
        //MultiHolder
        (component.parent as MultiHolder).replaceChild(component, comp);
        break;
      case 3:
        //Holder
        (component.parent as Holder).updateChild(comp);
        break;
      case 4:
        //CustomNamedHolder
        (component.parent as CustomNamedHolder).replaceChild(component, comp);
        break;
      case 5:
        (component.parent as CustomComponent).root = comp;
        comp.setParent(component.parent);
        break;
    }
  }

  void deleteCustomComponent(CustomComponent component) {
    for (CustomComponent component in component.objects) {
      removeComponent(component);
    }
    mainExecution.customComponents.remove(component);
    emit(ComponentUpdatedState());
  }

  void removeComponent(Component component) {
    if (component.parent == null) {
      return;
    }
    final parent = component.parent!;
    switch (parent.type) {
      case 2:
        (parent as MultiHolder).removeChild(component);
        switch (component.type) {
          case 1:
            break;
          case 2:
            parent.addChildren((component as MultiHolder).children);
            component.children.clear();
            break;
          case 3:
            if ((component as Holder).child != null) {
              parent.addChild(component.child!);
            }
            break;
        }

        break;
      case 3:
        switch (component.type) {
          case 1:
            (parent as Holder).updateChild(null);
            break;
          case 2:
            if ((component as MultiHolder).children.length == 1) {
              (parent as Holder).updateChild(component.children.first);
            } else {
              (parent as Holder).updateChild(null);
            }
            break;
          case 3:
            (parent as Holder).updateChild((component as Holder).child);
            break;
          case 4:
            (parent as Holder).updateChild(null);
            break;
          case 5:
            (parent as Holder).updateChild(null);
            break;
        }
        break;
      case 4:
        switch (component.type) {
          case 1:
            (parent as CustomNamedHolder).replaceChild(component, null);
            break;
          case 2:
            final key =
                (parent as CustomNamedHolder).replaceChild(component, null);
            if (key != null &&
                (component as MultiHolder).children.length == 1) {
              parent.childMap[key] = component.children.first;
              parent.childMap[key]?.setParent(parent);
            }
            break;
          case 3:
            final key =
                (parent as CustomNamedHolder).replaceChild(component, null);
            if (key != null) {
              parent.childMap[key] = (component as Holder).child;
              component.child?.setParent(parent);
            }
            break;
          case 4:
            (parent as CustomNamedHolder).updateChild(component, null);
            break;
          case 5:
            (parent as CustomNamedHolder).updateChild(component, null);
            break;
        }

        break;
      case 5:
        switch (component.type) {
          case 3:
            (parent as CustomComponent).root?.setParent(null);
            parent.root = (component as Holder).child;
            if (component.child != null) {
              component.child!.setParent(parent);
            }
            break;
          default:
            (parent as CustomComponent).root?.setParent(null);
            (parent).root = null;
        }
    }
  }
}
