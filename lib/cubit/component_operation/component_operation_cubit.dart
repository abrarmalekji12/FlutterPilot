import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../common/compiler/code_processor.dart';
import '../../common/undo/revert_work.dart';
import '../../injector.dart';
import '../../models/component_selection.dart';
import '../../models/local_model.dart';
import '../../models/variable_model.dart';
import '../../models/parameter_model.dart';
import '../../models/other_model.dart';
import '../../models/project_model.dart';
import '../../firestore/firestore_bridge.dart';
import '../../models/component_model.dart';
import '../../network/connectivity.dart';
import '../../runtime_provider.dart';
import '../component_creation/component_creation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';
import '../visual_box_drawer/visual_box_cubit.dart';

part 'component_operation_state.dart';

enum CustomWidgetType { stateless, stateful }

class ComponentOperationCubit extends Cubit<ComponentOperationState> {
  static FlutterProject? currentProject;
  List<ImageData>? imageDataList;
  final Map<Component, bool> expandedTree = {};
  final Map<String, List<Component>> sameComponentCollection = {};
  RuntimeMode runtimeMode = RuntimeMode.edit;
  final List<FavouriteModel> favouriteList = [];
  static Map<String, Uint8List> bytesCache = {};
  static late CodeProcessor processor;
  static late String componentId = '';

  ComponentOperationCubit() : super(ComponentOperationInitial()) {
    processor = get<CodeProcessor>();
  }

  List<LocalModel> get models => project!.currentScreen.models;

  RevertWork get revertWork => project!.currentScreen.revertWork;

  get byteCache => bytesCache;

  FlutterProject? get project => currentProject;

  set setFlutterProject(FlutterProject project) => currentProject = project;

  void addedComponent(Component component, Component root) {
    if (root is CustomComponent) {
      updateGlobalCustomComponent(root);
    }
    emit(ComponentUpdatedState());
  }

  Future<void> waitForConnectivity() async {
    if (!await AppConnectivity.available()) {
      if (state is! ComponentOperationErrorState) {
        emit(ComponentOperationErrorState('No Connection'));
      }
      final stream = AppConnectivity.listen();
      await for (final check in stream) {
        if (check != ConnectivityResult.none) {
          break;
        }
      }
    }
  }

  // static void changeVariables(final UIScreen screen) {
  //   ComponentOperationCubit.processor.variables
  //       .removeWhere((key, value) => value.deletable && !value.uiAttached);
  //   for (final entry in screen.variables.entries) {
  //     ComponentOperationCubit.processor.variables[entry.key] = entry.value;
  //   }
  // }

  // static void addVariables(final UIScreen screen) {
  //   for (final entry in screen.variables.entries) {
  //     ComponentOperationCubit.processor.variables[entry.key] = entry.value;
  //   }
  // }

  // static void removeVariables(final UIScreen screen) {
  //   ComponentOperationCubit.processor.variables
  //       .removeWhere((key, value) => screen.name == value.parentName);
  // }

  void changeProjectScreen(final UIScreen screen) {
    project!.currentScreen = screen;
    // changeVariables(screen);
    emit(ComponentUpdatedState());
    changeProjectScreenInDB();
  }

  void updateActionCode(final String value) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      project?.actionCode = value;
      await FireBridge.updateActionCode(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateCustomComponentActionCode(
      final CustomComponent component, final String value) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      component.actionCode = value;
      component.objects.forEach((element) {
        element.actionCode = value;
        element.processor.destroyProcess(deep: false);
        element.processor.executeCode(value, type: OperationType.checkOnly);
      });
      await FireBridge.updateCustomComponentActionCode(
          project!.userId, project!, component);
      refreshCustomComponents(component);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateScreenActionCode(final UIScreen screen, final String value) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      screen.actionCode = value;

      await FireBridge.updateScreenActionCode(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateProjectConfig(final String key, final dynamic value) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.updateProjectValue(project!, key, value);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> changeProjectScreenInDB() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.updateCurrentScreen(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateMainScreen() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.updateMainScreen(project!.userId, project!);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    emit(ComponentOperationInitial());
  }

  Future<void> updateGlobalCustomComponent(CustomComponent customComponent,
      {String? newName}) async {
    await waitForConnectivity();

    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.saveComponent(project!, customComponent,
          newName: newName);
      for (final Component comp in customComponent.objects) {
        comp.name = customComponent.name;
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void addOperation(Component component, Component comp, Component ancestor,
      {bool componentParameterOperation = false,
      ComponentParameter? componentParameter,
      String? customNamed}) {
    if (componentParameterOperation) {
      componentParameter!.addComponent(comp);
    } else if (customNamed != null) {
      (component as CustomNamedHolder)
          .addOrUpdateChildWithKey(customNamed, comp);
    } else {
      if (component is Holder) {
        component.updateChild(comp);
      } else if (component is MultiHolder) {
        component.addChild(comp);
      }
    }

    if (componentParameter == null) {
      comp.setParent(component);
      if (comp is CustomComponent) {
        comp.root?.setParent(component);
      }
      if (ancestor is CustomComponent) {
        if (component == ancestor) {
          ancestor.root = comp;
        }
        refreshCustomComponents(ancestor);
      }
    }
  }

  void refreshCustomComponents(CustomComponent customComponent) {
    customComponent.notifyChanged();
    final Map<String, List<String>> map = {};

    for (final CustomComponent comp in project?.customComponents ?? []) {
      if (customComponent != comp) {
        map[comp.name] = [];
        comp.forEach((p0) {
          if (p0 is CustomComponent) {
            map[comp.name]!.add(p0.name);
          }
        });
      }
    }
    final List<String> changeOrder = [customComponent.name];
    final list = map.entries.toList();
    list.sort((prev, next) => prev.value.length >= next.value.length ? 1 : -1);

    int index = 0;
    while (index < list.length) {
      for (final comp in changeOrder) {
        if (list[index].value.contains(comp)) {
          (project!.customComponents
                  .firstWhere((element) => element.name == list[index].key))
              .notifyChanged();
          changeOrder.add(list[index].key);
          break;
        }
      }
      index++;
    }
  }

  void addInSameComponentList(final Component component) {
    if (!sameComponentCollection.containsKey(component.name)) {
      sameComponentCollection[component.name] = [component];
    } else if (!sameComponentCollection[component.name]!.contains(component)) {
      for (final comp in sameComponentCollection[component.name]!) {
        if (component.id == comp.id) {
          return;
        }
      }
      sameComponentCollection[component.name]!.add(component);
    }
  }

  void extractSameTypeComponents(final Component root) {
    root.forEach((component) {
      addInSameComponentList(component);
    });
  }

  Future<List<ImageData>?> loadAllImages() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      final imageList = await FireBridge.loadAllImages(project!.userId);
      for (final ImageData image in imageList ?? []) {
        if (image.imageName != null) {
          byteCache[image.imageName!] = image.bytes!;
        }
      }
      imageDataList = imageList;
      emit(ComponentOperationInitial());
      return imageList;
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    return null;
  }

  void uploadImage(ImageData imageData) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.uploadImage(project!.userId, project!.name, imageData);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> deleteImage(String imgName) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.removeImage(project!.userId, imgName);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> deleteCurrentUIScreen(final UIScreen uiScreen) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await FireBridge.removeUIScreen(project!.userId, project!, uiScreen);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateRootComponent() async {
    await waitForConnectivity();

    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.updateScreenRootComponent(project!.userId, project!.name,
          project!.currentScreen, project!.rootComponent!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addUIScreen(final UIScreen uiScreen) async {
    project!.uiScreens.add(uiScreen);
    changeProjectScreen(uiScreen);
    await waitForConnectivity();
    emit(ComponentUpdatedState());
    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.addUIScreen(project!.userId, project!, uiScreen);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removedComponent() {
    emit(ComponentUpdatedState());
  }

  void arrangeComponent(
    BuildContext context,
    Component component,
    List<Component> children,
    int oldIndex,
    int newIndex,
    Component ancestor,
  ) {
    final old = children.removeAt(oldIndex);
    children.insert(newIndex, old);
    if (ancestor is CustomComponent) {
      refreshCustomComponents(ancestor);
    }
    BlocProvider.of<ComponentCreationCubit>(context).changedComponent();
    BlocProvider.of<VisualBoxCubit>(context).errorMessage = null;
    emit(ComponentUpdatedState());
  }

  void addCustomComponent(String name, CustomWidgetType type,
      {Component? root}) async {
    final CustomComponent component;
    if (type == CustomWidgetType.stateless) {
      component = StatelessComponent(
          name: name, actionCode: StatelessComponent.defaultActionCode);
    } else {
      component = StatefulComponent(
          name: name, actionCode: StatefulComponent.defaultActionCode);
    }
    project?.customComponents.add(component);
    if (root != null) {
      component.root = root;
      final instance = component.createInstance(root.parent);
      replaceChildOfParent(root, instance);
      root.parent = null;
      refreshCustomComponents(component);
    }

    try {
      await waitForConnectivity();
      await FireBridge.addNewGlobalCustomComponent(
          project!.userId, project!, component);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
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
      removeComponentAndRefresh(context, component, component);
    }
    project?.customComponents.remove(component);
    deleteCustomComponentOnCloud(component);
    emit(ComponentUpdatedState());
  }

  Future<void> deleteCustomComponentOnCloud(CustomComponent component) async {
    emit(ComponentOperationLoadingState());
    try {
      await FireBridge.deleteGlobalCustomComponent(
          project!.userId, project!, component);
      for (final customComp in currentProject!.customComponents) {
        await FireBridge.saveComponent(project!, customComp);
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removeRootComponentFromComponentParameter(
      ComponentParameter componentParameter, Component component,
      {bool removeAll = false}) {
    final index = componentParameter.components.indexOf(component);
    componentParameter.components.removeAt(index);
    switch (component.type) {
      case 1:
        break;
      case 3:
        if ((component as Holder).child != null && !removeAll) {
          componentParameter.components.insert(index, component.child!);
        }
        break;
    }
    emit(ComponentUpdatedState());
  }

  void removeComponent(Component component, Component ancestor) {
    if (ancestor is CustomComponent && component.parent == null) {
      switch (component.type) {
        case 1:
          break;
        case 2:
          ancestor.root = ((component as MultiHolder).children)[0];
          component.children.clear();
          break;
        case 3:
          ancestor.root = (component as Holder).child;
          break;
      }
      return;
    }
    final parent = component.parent!;
    if (component is CustomComponent) {
      (component.cloneOf as CustomComponent?)?.objects.remove(component);
    }
    switch (parent.type) {
      case 2:
        int index = (parent as MultiHolder).removeChild(component);
        switch (component.type) {
          case 1:
            break;
          case 2:
            parent.addChildren((component as MultiHolder).children,
                index: index);
            component.children.clear();
            break;
          case 3:
            if ((component as Holder).child != null) {
              parent.addChild(component.child!, index: index);
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

  void removeComponentAndRefresh(
      BuildContext context, Component component, Component ancestor) {
    removeComponent(component, ancestor);
    if (ancestor is CustomComponent) {
      refreshCustomComponents(ancestor);
    }
    emit(ComponentUpdatedState());
  }

  void refreshPropertyChanges(ComponentSelectionCubit cubit) {
    if (cubit.currentSelectedRoot is CustomComponent) {
      refreshCustomComponents(cubit.currentSelectedRoot as CustomComponent);
    }
    emit(ComponentUpdatedState());
  }

  bool isFavourite(final Component component) {
    if (project == null) {
      print('Method::isFavourite flutterProject is null');
      return false;
    }
    for (final favouriteComp in project?.favouriteList ?? []) {
      if (favouriteComp.component.id == component.id) {
        return true;
      }
    }
    return false;
  }

  void toggleFavourites(final Component component) {
    if (isFavourite(component)) {
      removeFromFavourites(component);
    } else {
      addToFavourites(component);
    }
  }

  Future<void> loadFavourites() async {
    emit(ComponentOperationLoadingState());
    final favouriteComponentList =
        await FireBridge.loadFavourites(project!.userId);
    favouriteList.clear();
    favouriteList.addAll(favouriteComponentList.reversed);
    project!.favouriteList.clear();
    for (final model in favouriteList) {
      if (model.projectName == project!.name) {
        project!.favouriteList.add(model);
      }
      addInSameComponentList(model.component);
    }

    final List<ImageData> imageDataList = [];
    for (final FavouriteModel model in favouriteComponentList) {
      model.component.forEach((component) {
        if (component.name == 'Image.asset') {
          final value = component.parameters[0].value;
          if (value != null) {
            imageDataList.add(value as ImageData);
          }
        }
      });
    }
    for (final imageData in imageDataList) {
      if (!byteCache.containsKey(imageData.imageName!)) {
        imageData.bytes =
            await FireBridge.loadImage(project!.userId, imageData.imageName!);
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
    final model = FavouriteModel(
        component.clone(null, deepClone: true)
          ..setId = component.id
          ..boundary = component.boundary,
        project!.name);
    if (favouriteList.isNotEmpty) {
      favouriteList.insert(0, model);
    } else {
      favouriteList.add(model);
    }
    final Rect? boundary;
    if (component.boundary == null) {
      boundary = component.cloneElements
          .firstWhereOrNull((element) => element.boundary != null)
          ?.boundary;
    } else {
      boundary = null;
    }
    double width, height;
    width = component.boundary?.width ?? boundary?.width ?? 1;
    height = component.boundary?.height ?? boundary?.height ?? 1;
    project!.favouriteList
        .add(model..component.boundary = Rect.fromLTWH(0, 0, width, height));
    try {
      await waitForConnectivity();

      await FireBridge.addToFavourites(
          project!.userId, component, project!.name, width, height);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    emit(ComponentUpdatedState());
  }

  void removeModelFromFavourites(final FavouriteModel model) async {
    emit(ComponentOperationLoadingState());
    favouriteList.remove(model);
    for (final favouriteModel in project!.favouriteList) {
      if (favouriteModel.component.id == model.component.id) {
        project!.favouriteList.remove(favouriteModel);
        break;
      }
    }
    try {
      await waitForConnectivity();

      await FireBridge.removeFromFavourites(project!.userId, model.component);
      emit(ComponentUpdatedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removeFromFavourites(final Component component) async {
    emit(ComponentOperationLoadingState());
    for (final model in favouriteList) {
      if (model.component.id == component.id) {
        favouriteList.remove(model);

        break;
      }
    }
    for (final model in project!.favouriteList) {
      if (model.component.id == component.id) {
        project!.favouriteList.remove(model);
        break;
      }
    }

    try {
      await waitForConnectivity();
      await FireBridge.removeFromFavourites(project!.userId, component);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    emit(ComponentUpdatedState());
  }

  bool shouldAddingEnable(
      Component component, Component? ancestor, String? customNamed) {
    return component is MultiHolder ||
        (component is Holder && component.child == null) ||
        (component.type == 5 &&
            component == ancestor &&
            (component as CustomComponent).root == null) ||
        (customNamed != null &&
            (component as CustomNamedHolder).childMap[customNamed] == null);
  }

  void removeAllComponent(Component component, Component ancestor) {
    if (ancestor is CustomComponent && component.parent == null) {
      ancestor.root = null;
      switch (component.type) {
        case 1:
          break;
        case 2:
          (component as MultiHolder).children.clear();
          break;
        case 3:
          (component as Holder).child = null;
          break;
      }
      return;
    }
    final parent = component.parent!;
    if (component.type == 2) {
      (component as MultiHolder).children.clear();
    } else if (component.type == 4) {
      (component as CustomNamedHolder).childMap.clear();
      component.childrenMap.clear();
    }
    switch (parent.type) {
      case 2:
        (parent as MultiHolder).removeChild(component);
        break;
      case 3:
        (parent as Holder).updateChild(null);
        break;
      case 4:
        (parent as CustomNamedHolder).replaceChild(component, null);
        break;
      case 5:
        (parent as CustomComponent).updateRoot(component);
        break;
    }
    if (ancestor is CustomComponent) {
      refreshCustomComponents(ancestor);
    }
  }

  Future<void> updateDeviceSelection(String name) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateDeviceSelection(project!.userId, project!, name);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addVariable(VariableModel variableModel) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      project!.variables[variableModel.name] = variableModel;
      await FireBridge.addVariable(project!.userId, project!, variableModel);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addVariableForScreen(VariableModel variableModel) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      project!.currentScreen.variables[variableModel.name] = variableModel;
      await FireBridge.addVariableForScreen(
          project!.userId, project!, variableModel);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateProjectSettings() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateSettings(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addModel(final LocalModel model) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.addModel(project!.userId, project!, model);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateModel(final LocalModel model) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateModel(project!.userId, project!, model);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateVariable() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateVariable(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateScreenVariable() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateUIScreenVariable(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateCustomVariable(final CustomComponent component) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await FireBridge.updateVariableForCustomComponent(
          project!.userId, project!, component);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }
}
