import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_builder/models/parameter_model.dart';
import '../../models/other_model.dart';
import '../../models/project_model.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/component_model.dart';
import '../component_creation/component_creation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../visual_box_drawer/visual_box_cubit.dart';

part 'component_operation_state.dart';

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  FlutterProject? flutterProject;
  final List<FavouriteModel> favouriteList = [];
  Map<String, Uint8List> byteCache = {};

  ComponentOperationCubit() : super(ComponentOperationInitial());

  void addedComponent(Component component, Component root) {
    if (root is CustomComponent) {
      updateGlobalCustomComponent(root);
    }
    emit(ComponentUpdatedState());
  }

  Future<void> updateGlobalCustomComponent(CustomComponent customComponent,
      {String? newName}) async {
    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.updateGlobalCustomComponent(
          1, flutterProject!.name, customComponent,
          newName: newName);
      emit(ComponentOperationInitial());
    } on Exception {
      emit(ComponentOperationErrorState());
    }
  }

  Future<List<ImageData>?> loadAllImages() async {
    emit(ComponentOperationLoadingState());
    final imageList = await FireBridge.loadAllImages(1);
    emit(ComponentOperationInitial());
    return imageList;
  }

  void uploadImage(ImageData imageData) async {
    emit(ComponentOperationLoadingState());
    await FireBridge.uploadImage(1, flutterProject!.name, imageData);
    emit(ComponentOperationInitial());
  }

  Future<void> deleteImage(String imgName) async {
    emit(ComponentOperationLoadingState());
    await FireBridge.removeImage(1, imgName);
    emit(ComponentOperationInitial());
  }

  Future<void> updateRootComponent() async {
    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.updateRootComponent(
          1, flutterProject!.name, flutterProject!.rootComponent!);
      emit(ComponentOperationInitial());
    } on Exception {
      emit(ComponentOperationErrorState());
    }
  }

  void removedComponent() {
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
    FireBridge.addNewGlobalCustomComponent(1, flutterProject!.name, component);
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

  void deleteCustomComponent(BuildContext context, CustomComponent component) {
    for (CustomComponent component in component.objects) {
      removeComponent(context, component);
    }
    flutterProject?.customComponents.remove(component);
    emit(ComponentUpdatedState());
  }

  void removeComponent(BuildContext context, Component component) {
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
    emit(ComponentUpdatedState());
  }

  bool isFavourite(final Component component) {
    bool favourite = false;
    for (final favouriteComp in flutterProject!.favouriteList) {
      if (favouriteComp.component.id == component.id) {
        favourite = true;
        break;
      }
    }
    return favourite;
  }

  void toggleFavourites(final Component component) {
    if (isFavourite(component)) {
      removeFromFavourites(component);
    } else {
      addToFavourites(component);
    }
  }

  Future<void> loadFavourites({String? projectName}) async {
    emit(ComponentOperationLoadingState());
    final favouriteComponentList =
        await FireBridge.loadFavourites(1, projectName: projectName);

    if (projectName != null) {
      flutterProject!.favouriteList.clear();
      flutterProject!.favouriteList.addAll(favouriteComponentList);
    } else {
      favouriteList.clear();
      favouriteList.addAll(favouriteComponentList);
    }
    final List<ImageData> imageDataList = [];
    for (final FavouriteModel model in favouriteComponentList) {
      model.component.forEach((component) {
        if (component.name == 'Image.asset') {
          imageDataList.add((component.parameters[0].value as ImageData));
        }
      });
    }
    for (final imageData in imageDataList) {
      if (!byteCache.containsKey(imageData.imageName!)) {
        imageData.bytes = await FireBridge.loadImage(1, imageData.imageName!);
        if (imageData.bytes != null) {
          byteCache[imageData.imageName!] = imageData.bytes!;
        }
      } else {
        imageData.bytes = byteCache[imageData.imageName!];
      }
    }
    emit(ComponentOperationInitial());
  }

  void addToFavourites(final Component component) async {
    emit(ComponentOperationLoadingState());
    flutterProject!.favouriteList.add(FavouriteModel(
        component.clone(null, cloneParam: true)
          ..id = component.id
          ..boundary = component.boundary,
        flutterProject!.name));
    await FireBridge.addToFavourites(1, component, flutterProject!.name);
    emit(ComponentUpdatedState());
  }

  void removeModelFromFavourites(final FavouriteModel model) async {
    emit(ComponentOperationLoadingState());
    favouriteList.remove(model);
    for (final favouriteModel in flutterProject!.favouriteList) {
      if (favouriteModel.component.id == model.component.id) {
        flutterProject!.favouriteList.remove(favouriteModel);
        break;
      }
    }
    await FireBridge.removeFromFavourites(1, model.component);
    emit(ComponentUpdatedState());
  }

  void removeFromFavourites(final Component component) async {
    emit(ComponentOperationLoadingState());
    for (final model in favouriteList) {
      if (model.component.id == component.id) {
        favouriteList.remove(model);

        break;
      }
    }
    for (final model in flutterProject!.favouriteList) {
      if (model.component.id == component.id) {
        flutterProject!.favouriteList.remove(model);
        break;
      }
    }

    await FireBridge.removeFromFavourites(1, component);
    emit(ComponentUpdatedState());
  }

  bool shouldAddingEnable(
      Component component,ComponentParameter? componentParameter, Component? ancestor, String? customNamed) {
    if(componentParameter!=null){
      return !componentParameter.isFull();
    }
    return component is MultiHolder ||
        (component is Holder && component.child == null) ||
        (component.type == 5 &&
            component == ancestor &&
            (component as CustomComponent).root == null) ||
        (customNamed != null &&
            (component as CustomNamedHolder).childMap[customNamed] == null);
  }

}
