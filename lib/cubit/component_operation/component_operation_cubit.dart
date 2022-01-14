import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/models/other_model.dart';
import '../../models/project_model.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/component_model.dart';
import '../component_creation/component_creation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../visual_box_drawer/visual_box_cubit.dart';

part 'component_operation_state.dart';

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  FlutterProject? flutterProject;

  ComponentOperationCubit() : super(ComponentOperationInitial());

  void addedComponent(
      BuildContext context, Component component, Component root) {
    BlocProvider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
        .changeComponentSelection(component, root: root);
    BlocProvider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;
    if (root is CustomComponent) {
      updateGlobalCustomComponent(root);
    }
    emit(ComponentUpdatedState());
  }

  void updateGlobalCustomComponent(CustomComponent customComponent,
      {String? newName}) {
    emit(ComponentOperationLoadingState());
    FireBridge.updateGlobalCustomComponent(1,flutterProject!.name,customComponent, newName: newName);
    emit(ComponentOperationInitial());
  }

  void uploadImage(ImageData imageData)async{
    emit(ComponentOperationLoadingState());
    await FireBridge.uploadImage(1, flutterProject!.name, imageData);
    emit(ComponentOperationInitial());
  }
  void loadImage(ImageData imageData)async{
    emit(ComponentOperationLoadingState());
    imageData.bytes=await FireBridge.loadImageBytes(1, flutterProject!.name,imageData.imagePath!);
    emit(ComponentOperationInitial());
  }
  void updateRootComponent(Component component) {
    emit(ComponentOperationLoadingState());
    FireBridge.updateRootComponent(1,flutterProject!.name,component);
    emit(ComponentOperationInitial());
  }



  void removedComponent(
      BuildContext context, Component component, Component root) {
    BlocProvider.of<ComponentSelectionCubit>(context, listen: false)
        .changeComponentSelection(component, root: root);
    BlocProvider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    BlocProvider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;
    emit(ComponentUpdatedState());
  }

  void arrangeComponent(
    BuildContext context,
  ) {
    BlocProvider.of<ComponentCreationCubit>(context, listen: false)
        .changedComponent();
    BlocProvider.of<VisualBoxCubit>(context, listen: false).errorMessage = null;
    emit(ComponentUpdatedState());
  }



  void addCustomComponent(String name, {Component? root}) {
    final component = StatelessComponent(name: name);
    flutterProject?.customComponents.add(component);
    FireBridge.addNewGlobalCustomComponent(1,flutterProject!.name,component);
    if (root != null) {
      component.root = root;
      final instance = component.createInstance(root.parent);
      replaceChildOfParent(root, instance);
      root.parent = null;
      component.notifyChanged();
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
    flutterProject?.customComponents.remove(component);
    emit(ComponentUpdatedState());
  }

  void removeComponent(Component component) {
    if (component.parent == null) {
      return;
    }
    final parent = component.parent!;
    if (component is CustomComponent) {
      component.cloneOf?.objects.remove(component);
    }
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
