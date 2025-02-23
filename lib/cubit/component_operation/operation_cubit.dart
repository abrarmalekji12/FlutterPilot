import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/processor_component.dart';
import 'package:get/get.dart';

import '../../bloc/state_management/state_management_bloc.dart';
import '../../code_operations.dart';
import '../../collections/project_info_collection.dart';
import '../../common/undo/revert_work.dart';
import '../../data/remote/firestore/firebase_bridge.dart';
import '../../injector.dart';
import '../../mode_converters/figma/data/api_client.dart';
import '../../mode_converters/figma/data/models/figma_file_response.dart';
import '../../mode_converters/figma/figma_analyzer.dart';
import '../../mode_converters/figma/figma_to_fvb_converter.dart';
import '../../models/actions/action_model.dart';
import '../../models/builder_component.dart';
import '../../models/component_selection.dart';
import '../../models/fvb_ui_core/component/component_model.dart';
import '../../models/fvb_ui_core/component/custom_component.dart';
import '../../models/global_component.dart';
import '../../models/operation_model.dart';
import '../../models/other_model.dart';
import '../../models/parameter_model.dart';
import '../../models/project_model.dart';
import '../../models/template_model.dart';
import '../../models/variable_model.dart';
import '../../network/connectivity.dart';
import '../../runtime_provider.dart';
import '../../ui/boundary_widget.dart';
import '../../ui/modification_helper/modification_helper.dart';
import '../../ui/navigation/animated_dialog.dart';
import '../../user_session.dart';
import '../component_creation/component_creation_cubit.dart';
import '../component_selection/component_selection_cubit.dart';

part 'operation_state.dart';

enum CustomWidgetType { stateless, stateful }

Component? processComponent;
Parameter? processParameter;
final Map<String, Uint8List> byteCache = {};

class OperationCubit extends Cubit<OperationState> {
  final SelectionCubit selectionCubit;
  List<FVBImage>? imageDataList;
  Map<String, List<CustomComponent>>? allCustoms;
  final Map<Component, bool> expandedTree = {};
  final Map<String, List<Component>> sameComponentCollection = {};
  static late Processor paramProcessor;
  List<TemplateModel>? templateList;
  final List<GlobalComponentModel> componentList = [];
  final CreationCubit creationCubit;
  final UserProjectCollection collection;
  final FigmaApiClient _figmaApiClient;
  final UserSession _userSession;
  final _figmaAnalyzer = FigmaAnalyzer();
  final _converter = FigmaToFVBConverter();

  OperationCubit(this.selectionCubit, this.creationCubit, this.collection,
      this._figmaApiClient, this._userSession)
      : super(ComponentOperationInitial()) {
    paramProcessor = sl<Processor>();
  }

  RevertWork get revertWork => collection.project!.revertWork;

  FVBProject? get project => collection.project;

  set setFlutterProject(FVBProject project) => collection.project = project;

  void updateState(Component root) {
    if (root is CustomComponent) {
      updateGlobalCustomComponent(root);
    }
    emit(ComponentUpdatedState());
  }

  void update() {
    emit(ComponentUpdatedState());
  }

  void customComponentVariableUpdated() {
    emit(CustomComponentVariableUpdatedState());
  }

  Future<void> waitForConnectivity() async {
    if (!await AppConnectivity.available()) {
      if (state is! ComponentOperationErrorState) {
        emit(ComponentOperationErrorState('No Connection',
            type: ErrorType.network));
      }
      final stream = AppConnectivity.listen();
      await for (final check in stream) {
        if (check.isNotEmpty) {
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

  // void changeProjectScreen(final UIScreen screen) {
  //   project!.currentScreen = screen;
  //   // changeVariables(screen);
  //   emit(ComponentUpdatedState());
  //   changeProjectScreenInDB();
  // }

  void parameterChangeRevert(
      Parameter parameter, VoidCallback onRevert, FVBProject project) {
    revertWork.add(parameter.toJson(), () {}, (p0) {
      parameter.fromJson(p0, project);
      onRevert();
    });
    emit(ComponentUpdatedState());
  }

  void updateActionCode(final String value) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      project?.actionCode = value;
      await dataBridge.updateActionCode(project!.userId, project!);
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
      await dataBridge.updateCustomComponentActionCode(component);
      refreshCustomComponents(component);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateCustomComponentArguments(final CustomComponent component) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateCustomComponentArguments(component);
      // refreshCustomComponents(component);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateScreenActionCode(
      final Viewable viewable, final String value) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      viewable.actionCode = value;
      if (viewable is Screen) {
        await dataBridge.updateScreenActionCode(
            project!.userId, project!, viewable);
      } else {
        await dataBridge.updateCustomComponentActionCode(
          viewable as CustomComponent,
        );
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateProjectConfig(final String key, final dynamic value) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateProjectValue(project!, key, value);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateApiData() async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateProjectValue(
          project!, 'apiModel', project!.apiModel.toJson());
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateUserSetting(final String key, final dynamic value) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateUserValue(_userSession.user.userId!, key, value);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> changeProjectScreenInDB() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateCurrentScreen(
          project!.userId, project!, selectionCubit.selected.viewable!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removeComponentOperation(BuildContext context, Component component,
      Component ancestor, Viewable? screen) {
    final parent = component.parent;

    if (ancestor is CustomComponent) {
      removeComponentAndRefresh(context, component, ancestor);
      selectionCubit.changeComponentSelection(
        ComponentSelectionModel.unique(
            (parent is Component
                    ? parent
                    : (parent != null ? parent.parent : null)) ??
                ancestor,
            ancestor,
            screen: screen),
      );
      if (parent is Component) {
        context
            .read<StateManagementBloc>()
            .add(StateManagementRefreshEvent(parent.id, RuntimeMode.edit));
      } else {
        creationCubit.changedComponent(ancestor: ancestor);
      }
    } else {
      if (component == ancestor) {
        switch (component.type) {
          case 3:
            screen?.rootComponent = (component as Holder).child;
            break;
          case 2:
            screen?.rootComponent =
                (component as MultiHolder).children.isNotEmpty
                    ? component.children.first
                    : null;
            break;
          default:
            screen?.rootComponent = null;
        }
        if (screen?.rootComponent != null) {
          selectionCubit.changeComponentSelection(
              ComponentSelectionModel.unique(
                  screen!.rootComponent!, screen.rootComponent!,
                  screen: screen));
        }
        if (parent is Component) {
          context
              .read<StateManagementBloc>()
              .add(StateManagementRefreshEvent(parent.id, RuntimeMode.edit));
        } else {
          creationCubit.changedComponent(ancestor: ancestor);
        }
        return;
      }
      removeComponentAndRefresh(context, component, ancestor);
      if (parent != null) {
        selectionCubit.changeComponentSelection(ComponentSelectionModel.unique(
            parent is ComponentParameter ? parent.parent : parent, ancestor,
            screen: screen));
      }
      if (parent is Component) {
        context
            .read<StateManagementBloc>()
            .add(StateManagementRefreshEvent(parent.id, RuntimeMode.edit));
      } else {
        creationCubit.changedComponent(ancestor: ancestor);
      }
    }
  }

  Future<void> updateMainScreen() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.updateMainScreen(project!.userId, project!);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    emit(ComponentOperationInitial());
  }

  Future<void> updateRootOnFirestore() async {
    final root = selectionCubit.selected.root;
    if (root is CustomComponent) {
      await updateGlobalCustomComponent(root);
    } else if (selectionCubit.selected.viewable != null) {
      await updateRootComponent(selectionCubit.selected.viewable!);
    }
  }

  Future<void> updateGlobalCustomComponent(
      CustomComponent customComponent) async {
    await waitForConnectivity();

    emit(ComponentOperationLoadingState());
    try {
      await dataBridge.updateCustomComponent(project!, customComponent);
      for (final Component comp in customComponent.objects) {
        comp.name = customComponent.name;
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addOperation(BuildContext context, Component component,
      Component comp, Component ancestor,
      {bool componentParameterOperation = false,
      int? index,
      bool undo = false,
      ComponentParameter? componentParameter,
      String? customNamed}) async {
    if (undo) {
      if (needToCallHelper(comp, component)) {
        Component? updated;
        await AnimatedDialog.show(
            context,
            ComponentModificationHelper(
              onUpdated: (Component value) {
                updated = value;
              },
              component: comp,
            ));
        if (updated == null) {
          return;
        }
        comp = updated!;
      }
      revertWork.add([comp, ancestor], () {}, (p0) {
        final parent = (p0[0] as Component).parent;
        removeComponent(p0[0], p0[1]);
        emit(ComponentUpdatedState());
        if (parent is Component) {
          context
              .read<StateManagementBloc>()
              .add(StateManagementRefreshEvent(parent.id, RuntimeMode.edit));
        } else {
          creationCubit.changedComponent(ancestor: ancestor);
        }
      });
    }
    if (componentParameterOperation) {
      componentParameter!.addComponent(comp, index: index);
    } else if (customNamed != null) {
      (component as CustomNamedHolder)
          .addOrUpdateChildWithKey(customNamed, comp);
    } else if (component is Holder) {
      component.updateChild(comp);
    } else if (component is MultiHolder) {
      component.addChild(comp, index: index);
    }

    /// When component is custom component
    if (componentParameter == null) {
      comp.setParent(component);
      if (comp is CustomComponent) {
        comp.rootComponent?.setParent(component);
      }
      if (ancestor is CustomComponent) {
        if (component == ancestor) {
          ancestor.updateRoot(comp);
        }
      }
    }
  }

  void reversibleParameterOperation(p0, void Function() work,
      void Function(dynamic, Component component) revert) {
    final component = selectionCubit.selected.propertySelection;
    revertWork.add(p0, work, (old) {
      revert.call(old, component);
    });
  }

  void reversibleComponentOperation(
      Viewable viewable, void Function() work, Component ancestor) {
    final Operation operation;
    if (ancestor is CustomComponent) {
      operation = Operation(ancestor.rootComponent?.toJson(),
          selectionCubit.selected.treeSelection.first.id);
    } else {
      operation = Operation(
          ancestor.toJson(), selectionCubit.selected.treeSelection.first.id);
    }
    revertWork.add(operation, work, (p0) {
      final Operation operation = p0;
      if (ancestor is CustomComponent) {
        if (operation.data != null) {
          (ancestor).rootComponent =
              Component.fromJson(operation.data, project!);
        }
        emit(ComponentUpdatedState());
        refreshCustomComponents(ancestor);
        ancestor.rootComponent?.forEachWithClones((comp) {
          if (comp.hasImageAsset) {
            final imageData = (comp.parameters[0].value as FVBImage);
            if (byteCache.containsKey(imageData.name)) {
              imageData.bytes = byteCache[imageData.name];
            }
          }
          if (comp.id == operation.selectedId) {
            selectionCubit.changeComponentSelection(
                ComponentSelectionModel.unique(comp, ancestor,
                    screen: viewable));
          }
          return false;
        });
      } else {
        selectionCubit.selected.viewable?.rootComponent = operation.data != null
            ? Component.fromJson(operation.data, project!)
            : null;
        emit(ComponentUpdatedState());
        selectionCubit.selected.viewable?.rootComponent
            ?.forEachWithClones((comp) {
          if (comp.hasImageAsset) {
            final imageData = (comp.parameters[0].value as FVBImage);
            if (byteCache.containsKey(imageData.name)) {
              imageData.bytes = byteCache[imageData.name];
            }
          }
          if (comp.id == operation.selectedId) {
            selectionCubit.changeComponentSelection(
                ComponentSelectionModel.unique(comp, ancestor,
                    screen: viewable));
          }
          return false;
        });
      }
      creationCubit.changedComponent(ancestor: ancestor);
    });
  }

  void refreshCustomComponents(CustomComponent customComponent) {
    customComponent.notifyChanged();
    final Map<String, List<String>> map = {};

    for (final CustomComponent comp in project?.customComponents ?? []) {
      if (customComponent != comp) {
        map[comp.name] = [];
        comp.forEachWithClones((p0) {
          if (p0 is CustomComponent) {
            map[comp.name]!.add(p0.name);
          }
          return false;
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
    root.forEachWithClones((component) {
      addInSameComponentList(component);
      return false;
    });
  }

  Future<List<FVBImage>?> loadAllImages(String userId) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      final imageList = await dataBridge.loadAllImages(userId);
      for (final FVBImage image in imageList ?? []) {
        if (image.name != null) {
          byteCache[image.name!] = image.bytes!;
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

  Future<Map<String, List<CustomComponent>>?> loadAllCustomComponents() async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      allCustoms = await dataBridge.loadAllCustomComponents(project!.userId);
      emit(ComponentOperationInitial());
      return allCustoms;
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    return null;
  }

  Future<void> uploadImage(FVBImage imageData) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.uploadImage(project!.userId, project!.id, imageData);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void uploadPublicImage(FVBImage imageData) async {
    await waitForConnectivity();

    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.uploadPublicImage(imageData);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> deleteImage(String imgName) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      await dataBridge.removeImage(project!.userId, imgName);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> deleteCurrentUIScreen(final Viewable screen) async {
    await waitForConnectivity();
    try {
      emit(ComponentOperationLoadingState());
      if (screen is Screen) {
        await dataBridge.removeScreen(project!.userId, project!, screen);
      } else {
        await dataBridge.removeCustomComponent(
            project!.userId, project!, screen as CustomComponent);
      }
      emit(ComponentOperationScreensUpdatedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateRootComponent(Viewable screen) async {
    emit(ComponentUpdatedState());
    await waitForConnectivity();

    emit(ComponentOperationLoadingState());
    try {
      if (screen is Screen) {
        await dataBridge.updateScreenRootComponent(
            project!.userId, screen, screen.rootComponent);
      } else if (screen is FVBProject) {
        await dataBridge.updateProjectRootComponent(project!);
      } else if (screen is CustomComponent) {
        await dataBridge.updateCustomComponent(project!, screen);
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      print('ERROR ${e.toString()}');
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateProjectRootComponent(FVBProject project) async {
    emit(ComponentUpdatedState());
    await waitForConnectivity();

    emit(ComponentOperationLoadingState());
    try {
      await dataBridge.updateProjectRootComponent(project);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      print('ERROR ${e.toString()}');
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  FigmaFileResponse? response;
  FigmaDocumentMeta? figmaDocumentMeta;

  Future<bool> addScreensFromFigma(
      final String figmaToken, String figmaLink) async {
    try {
      if (response != null && figmaDocumentMeta != null) {
        emit(ComponentOperationLoadingFigmaScreensState());
        final screens =
            _converter.convert(project!, response!.document, figmaDocumentMeta);
        if (screens != null) {
          project!.screens.removeRange(
              project!.screens.length - screens.length + 1,
              project!.screens.length);
        }
        project!.screens.addAll(screens ?? []);
        emit(ComponentOperationFigmaScreensConvertedState(screens ?? []));
        return true;
      }
      await waitForConnectivity();
      emit(ComponentOperationLoadingFigmaScreensState());
      final initialIndex = figmaLink.indexOf('/file/');
      if (initialIndex + 6 >= 0) {
        final keyPart = figmaLink.substring(initialIndex + 6);
        final endIndex = keyPart.indexOf('/');
        if (endIndex >= 0) {
          final key = keyPart.substring(0, endIndex);
          response =
              await _figmaApiClient.getFigmaFile(key, 'Bearer $figmaToken');
          figmaDocumentMeta = FigmaDocumentMeta(vectorNodesImages: {});
          figmaDocumentMeta!.images = await _figmaApiClient.getFigmaFileImages(
              key, 'Bearer $figmaToken'); //'YAzoE08Qr3RFM1ybSzTSPP'
          final config = _figmaAnalyzer.analyzeConfiguration(response!);
          if (config.vectorNodes.isNotEmpty) {
            final figmaNodeImagesResponse =
                await _figmaApiClient.getNodesImages(key, 'Bearer $figmaToken',
                    config.vectorNodes.map((e) => e.id).join(','), 'png', true,
                    scale: '1.5');
            if (figmaNodeImagesResponse.images != null) {
              figmaDocumentMeta!.vectorNodesImages.addAll(
                  figmaNodeImagesResponse.images!
                      .map((key, value) => MapEntry(key, value ?? '')));
            }
            final screens = _converter.convert(
                project!, response!.document, figmaDocumentMeta);
            await Future.wait<bool>(
                screens?.map((e) async => await addScreen(e)) ?? []);
            emit(ComponentOperationFigmaScreensConvertedState(screens ?? []));
            return true;
          }
        }
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    return false;
  }

  Future<bool> addScreen(final Screen screen) async {
    try {
      if (project!.screens.isEmpty) {
        project!.mainScreen = screen;
        await updateMainScreen();
      }
      project!.screens.add(screen);
      // changeProjectScreen(uiScreen);
      await waitForConnectivity();
      emit(ComponentUpdatedState());
      emit(ComponentOperationScreenAddingState());
      await dataBridge.createScreen(project!.userId, project!, screen);
      emit(ComponentOperationScreensUpdatedState());
      return true;
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    return false;
  }

  void removedComponent() {
    emit(ComponentUpdatedState());
  }

  void arrangeComponent(BuildContext context, Component component, int oldIndex,
      int newIndex, Component ancestor,
      {String? named, ComponentParameter? parameter}) {
    if (component is MultiHolder) {
      final Component old = component.children.removeAt(oldIndex);
      component.children.insert(newIndex, old);
      component.getAllClones().forEach((comp) {
        final oldComp = (comp as MultiHolder).children.removeAt(oldIndex);
        comp.children.insert(newIndex, oldComp);
      });
    } else if (named != null) {
      if ((component as CustomNamedHolder).childrenMap.containsKey(named)) {
        final old = component.childrenMap[named]?.removeAt(oldIndex);
        component.childrenMap[named]?.insert(newIndex, old!);
        component.getAllClones().forEach((element) {
          final old = (element as CustomNamedHolder)
              .childrenMap[named]
              ?.removeAt(oldIndex);
          element.childrenMap[named]?.insert(newIndex, old!);
        });
      }
    } else if (parameter != null) {
      final old = parameter.components.removeAt(oldIndex);
      parameter.components.insert(newIndex, old);
      component.getAllClones().forEach((element) {
        final cloneParam = element.componentParameters
            .firstWhere((cp) => cp.displayName == parameter.displayName);
        final old = cloneParam.components.removeAt(oldIndex);
        cloneParam.components.insert(newIndex, old);
      });
    }
    creationCubit.changedComponent(ancestor: ancestor);
    emit(ComponentUpdatedState());
  }

  void addCustomComponent(String name, CustomWidgetType type,
      {Component? root}) async {
    final CustomComponent component;
    if (type == CustomWidgetType.stateless) {
      component = StatelessComponent(
          name: name,
          project: collection.project!,
          userId: _userSession.user.userId!,
          id: randomId);
    } else {
      component = StatefulComponent(
          name: name,
          project: collection.project!,
          userId: _userSession.user.userId!,
          id: randomId);
    }
    project?.customComponents.add(component);
    if (root != null) {
      component.rootComponent = root;
      final instance = component.createInstance(root.parent);
      replaceChildOfParent(root, instance);
      root.parent = null;
      refreshCustomComponents(component);
    }
    saveCustomComponent(component);
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
        (component.parent as CustomComponent).rootComponent = comp;
        comp.setParent(component.parent);
        break;
    }
  }

  void deleteCustomComponent(BuildContext context, CustomComponent component) {
    // if(undo){
    //   revertWork.add(component.objects.toList(), () { }, (p0) {
    //     project?.customComponents.add(component);
    //     saveCustomComponent(component);
    //     for(final a in (p0 as List<CustomComponent>)){
    //       addOperation(component, comp, ancestor)
    //     }
    //   });
    // }
    while (component.objects.isNotEmpty) {
      removeComponentAndRefresh(
          context, component.objects.removeLast(), component);
    }
    project?.customComponents.remove(component);
    deleteCustomComponentOnCloud(component);
    emit(ComponentUpdatedState());
  }

  void uploadTemplate(TemplateModel model) async {
    await waitForConnectivity();
    emit(ComponentOperationTemplateUploadingState());
    try {
      await dataBridge.uploadTemplate(model);
      for (final customComp in collection.project!.customComponents) {
        await dataBridge.updateCustomComponent(project!, customComp);
      }
      templateList?.add(model);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void deleteTemplate(TemplateModel model) async {
    await waitForConnectivity();
    emit(ComponentOperationLoadingState());
    try {
      await dataBridge.deleteTemplate(model);
      templateList!.remove(model);
      emit(ComponentOperationTemplateLoadedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void loadTemplates(String? userId) async {
    await waitForConnectivity();
    emit(ComponentOperationLoadingState());
    try {
      templateList =
          (await dataBridge.loadScreenTemplateList(null, 10, userId: userId))
              .models;
      emit(ComponentOperationTemplateLoadedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> loadGlobalComponentList() async {
    await waitForConnectivity();
    emit(ComponentOperationComponentLoadingState());
    try {
      componentList.clear();
      componentList.addAll((await dataBridge.loadGlobalComponentList()) ?? []);
      componentList.sort((first, second) =>
          first.category != null && second.category != null
              ? first.category!.compareTo(second.category!)
              : 1);
      emit(ComponentOperationComponentsLoadedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> deleteCustomComponentOnCloud(CustomComponent component) async {
    await waitForConnectivity();
    emit(ComponentOperationLoadingState());
    try {
      await dataBridge.removeCustomComponent(
          project!.userId, project!, component);
      for (final customComp in collection.project!.customComponents) {
        await dataBridge.updateCustomComponent(project!, customComp);
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removeRootComponentFromComponentParameter(
      ComponentParameter componentParameter, Component component,
      {bool removeAll = false}) {
    componentParameter.removeComponent(component, removeAll: removeAll);
    emit(ComponentUpdatedState());
  }

  Component? duplicateComponent(
      Component component, Component ancestor, String? named) {
    Component? parent = component;
    while (parent?.parent != null) {
      parent = parent?.parent;

      if (parent is MultiHolder || parent is CustomNamedHolder) {
        break;
      }
    }
    final clone = component.clone(null, deepClone: true, connect: false);
    if (parent is MultiHolder) {
      parent.addChild(clone);
      // if (ancestor is CustomComponent) {
      //   refreshCustomComponents(ancestor);
      // }
      return clone;
    } else if (parent is CustomNamedHolder && named != null) {
      parent.addOrUpdateChildWithKey(named, clone);
      return clone;
    }

    return null;
  }

  void copyValueSourceToDest(Parameter source, Parameter dest) {
    if (source is SimpleParameter) {
      (dest as SimpleParameter).compiler.code = source.compiler.code;
    } else if (source is BooleanParameter) {
      (dest as BooleanParameter).compiler.code = source.compiler.code;
    } else if (source is ChoiceValueParameter) {
      (dest as ChoiceValueParameter).val = source.val;
    } else if (source is ChoiceParameter && source.val != null) {
      final sourceSelectionName = source.val?.displayName;
      for (final option in (dest as ChoiceParameter).options) {
        if (option.displayName == sourceSelectionName) {
          dest.val = option;
          copyValueSourceToDest(source.val!, dest.val!);
          break;
        }
      }
    } else if (source is ComplexParameter) {
      for (final param in source.params) {
        for (final param2 in (dest as ComplexParameter).params) {
          if ((param.displayName == param2.displayName) &&
              param.runtimeType == param2.runtimeType) {
            copyValueSourceToDest(param, param2);
          }
        }
      }
    }
  }

  void replaceWith(Component oldComponent, Component comp, Component ancestor) {
    if (oldComponent.runtimeType != comp.runtimeType) {
      for (final source in oldComponent.parameters) {
        for (final dest in comp.parameters) {
          if (source.runtimeType == dest.runtimeType &&
              dest.displayName == source.displayName) {
            copyValueSourceToDest(source, dest);
          }
        }
      }
    }
    if (comp.type == oldComponent.type) {
      switch (comp.type) {
        case 2:
          //MultiHolder
          final children = (comp as MultiHolder).children;
          (comp).children = (oldComponent as MultiHolder).children;
          oldComponent.children = children;
          oldComponent.children.forEach((element) {
            element.parent = oldComponent;
          });
          comp.children.forEach((element) {
            element.parent = comp;
          });

          break;
        case 3:
          //Holder
          final temp = (comp as Holder).child;
          (comp).updateChild((oldComponent as Holder).child);
          oldComponent.updateChild(temp);

          break;
        case 4:
          for (final child
              in (oldComponent as CustomNamedHolder).childMap.entries) {
            if (child.value != null &&
                (comp as CustomNamedHolder).childMap.containsKey(child.key)) {
              (comp).childMap[child.key] = child.value;
              if (comp is BuilderComponent &&
                  oldComponent is BuilderComponent &&
                  oldComponent.functionMap[child.key] != null) {
                comp.functionMap[child.key] =
                    oldComponent.functionMap[child.key]!;
              }
            }
          }
          for (final child in oldComponent.childrenMap.entries) {
            if (child.value.isNotEmpty &&
                (comp as CustomNamedHolder)
                    .childrenMap
                    .containsKey(child.key)) {
              (comp).childrenMap[child.key] = child.value;
              if (comp is BuilderComponent &&
                  oldComponent is BuilderComponent &&
                  oldComponent.functionMap[child.key] != null) {
                comp.functionMap[child.key] =
                    oldComponent.functionMap[child.key]!;
              }
            }
          }
          break;
      }
    }
    replaceChildOfParent(oldComponent, comp);
    // final compParent = comp.parent;
    // replaceChildOfParent(comp, oldComponent);
    // if(compParent!=null)
    // replaceChildOfParent(oldComponent, compParent);

    // if (ancestor is CustomComponent) {
    //   componentOperationCubit
    //       .refreshCustomComponents(ancestor as CustomComponent);
    // }
  }

  void wrapWithComponent(final Component component, final Component wrapperComp,
      final Component ancestor, Viewable? screen,
      {String? customName, bool undo = false}) {
    if (undo) {
      revertWork.add(wrapperComp, () {}, (p0) {
        removeComponent(p0, ancestor);
        emit(ComponentUpdatedState());
        creationCubit.changedComponent(ancestor: ancestor);
      });
    }
    if (component.parent is ComponentParameter) {
      component.parent.replace(component, wrapperComp);
    } else if (component == ancestor) {
      screen?.rootComponent = wrapperComp;
      component.parent = wrapperComp;
    } else {
      if (ancestor is CustomComponent && ancestor.rootComponent == component) {
        ancestor.updateRoot(wrapperComp);
      } else {
        replaceChildOfParent(component, wrapperComp);
      }
    }
    if (customName != null) {
      (wrapperComp as CustomNamedHolder)
          .addOrUpdateChildWithKey(customName, component);
    } else {
      switch (wrapperComp.type) {
        case 2:
          //MultiHolder
          (wrapperComp as MultiHolder).addChild(component);
          break;
        case 3:
          //Holder
          (wrapperComp as Holder).updateChild(component);
          break;
      }
    }
  }

  void removeComponent(Component component, Component ancestor) {
    if (component.parent is ComponentParameter) {
      removeRootComponentFromComponentParameter(component.parent, component);
      return;
    } else if (ancestor is CustomComponent && component.parent == null) {
      switch (component.type) {
        case 1:
          break;
        case 2:
          ancestor.rootComponent = ((component as MultiHolder).children)[0];
          component.children.clear();
          component.getAllClones().forEach((element) {
            (element as MultiHolder).children.clear();
          });
          break;
        case 3:
          ancestor.updateRoot((component as Holder).child);
          break;
        case 4:
          ancestor.updateRoot(null);
          break;
      }
      return;
    }
    final parent = component.parent!;
    if (parent is Component) {
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
              (parent as CustomNamedHolder).replaceChild(
                  component,
                  (component as MultiHolder).children.isNotEmpty
                      ? (component).children.first
                      : null);
              break;
            case 3:
              (parent as CustomNamedHolder)
                  .replaceChild(component, (component as Holder).child);
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
              (parent as CustomComponent)
                  .updateRoot((component as Holder).child);

              break;
            default:
              (parent as CustomComponent).updateRoot(null);
          }
      }
    }
  }

  void removeComponentAndRefresh(
      BuildContext context, Component component, Component ancestor) {
    revertWork.add([
      component.parent,
      (component.parent is MultiHolder)
          ? (component.parent! as MultiHolder).children.indexOf(component)
          : null,
      (component.parent is CustomNamedHolder)
          ? ((component.parent! as CustomNamedHolder)
                  .childMap
                  .entries
                  .firstWhereOrNull((element) => element.value == component)
                  ?.key ??
              (component.parent! as CustomNamedHolder)
                  .childrenMap
                  .entries
                  .firstWhereOrNull(
                      (element) => element.value.contains(component))
                  ?.key)
          : null
    ], () {}, (p0) async {
      await addOperation(
        context,
        p0[0] is ComponentParameter
            ? (p0[0] as ComponentParameter).parent
            : p0[0],
        component,
        ancestor,
        index: p0[1],
        customNamed: p0[2],
        componentParameter: p0[0] is ComponentParameter ? p0[0] : null,
        componentParameterOperation: p0[0] is ComponentParameter ? true : false,
      );
      emit(ComponentUpdatedState());
      creationCubit.changedComponent(ancestor: ancestor);
    });
    removeComponent(component, ancestor);
    emit(ComponentUpdatedState());
  }

  void refreshPropertyChanges(SelectionCubit cubit) {
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
    for (final FavouriteModel favouriteComp in collection.favouriteList) {
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
    try {
      emit(ComponentOperationLoadingState());
      final favouriteComponentList =
          await dataBridge.loadFavourites(_userSession.user.userId!);
      collection.favouriteList.clear();
      collection.favouriteList.addAll(favouriteComponentList);
      final List<FVBImage> imageDataList = [];
      for (final FavouriteModel model in favouriteComponentList) {
        model.component.forEachWithClones((component) {
          if (component.hasImageAsset && component.parameters.isNotEmpty) {
            final value = component.parameters[0].value;
            if (value != null) {
              imageDataList.add(value as FVBImage);
            }
          }
          return false;
        });
      }
      await Future.wait(imageDataList.map((imageData) async {
        if (!byteCache.containsKey(imageData.name!)) {
          imageData.bytes = await dataBridge.loadImage(
              _userSession.user.userId!, imageData.name!);
        } else {
          imageData.bytes = byteCache[imageData.name!];
        }
      }));
      emit(ComponentFavouriteLoadedState());
    } on Exception catch (e) {
      debugPrint('Error loading favourites :: ${e.toString()}');
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  ValidationErrorReport? validateComponent(Component component,
      Component ancestor, Viewable? screen, List<String> avoidScopes) {
    bool valid = true;
    final Map<Component, String> errorLines = {};
    disableError = true;
    Processor.operationType = OperationType.checkOnly;
    Processor.checkOnlyConfig = CheckOnlyConfig(avoidScopes);
    final processor = component.parentProcessor(screen, ancestor)!;
    int count = 0;
    void noteError(String code, Component component) {
      if (Processor.error) {
        valid = false;
        count++;
        errorLines[component] = code + '|' + Processor.errorMessage;
      }
    }

    final Map<String, List<Component>> clearList = {};
    final Map<String, List<String>> removeVars = {};
    component.forEachWithClones((p0) {
      if (p0 is CustomComponent) {
        final List<dynamic> argValueList = [];
        for (final arg in p0.arguments) {
          if (Processor.error) {
            Processor.error = false;
          }
          argValueList.add(processor.process(CodeOperations.trim(arg)!,
              config: const ProcessorConfig(unmodifiable: true)));
          noteError(arg, p0);
        }
        final List<String> list = [];
        for (int i = 0; i < p0.argumentVariables.length; i++) {
          if (Processor.error) {
            Processor.error = false;
          }
          if (p0 is StatelessComponent) list.add(p0.argumentVariables[i].name);
          p0.applyVariables(processor, target: processor);
        }
        if (p0 is StatefulComponent) {
          list.add('widget');
        }
        removeVars[p0.name] = list;
        final List<Component> componentList = [];
        p0.forEachWithClones((p0) {
          componentList.add(p0);
          return false;
        });
        clearList[p0.name] = componentList;
      }

      if (p0 is Clickable) {
        for (final action in (p0 as Clickable).actionList) {
          if (action is CustomAction) {
            processor.executeCode(action.arguments[0],
                config: const ProcessorConfig(unmodifiable: true));
            for (final method in processor.functions.entries) {
              method.value.execute(
                  processor,
                  null,
                  method.value.arguments
                      .map((e) => FVBCacheValue(FVBAnalysisPlace.any,
                          e.dataType.copyWith(nullable: e.nullable)))
                      .toList(growable: false));
              noteError(action.arguments[0], component);
            }
            noteError(action.arguments[0], component);
          }
        }
        noteError(
            (p0 as Clickable).actionList.map((e) => e.arguments[0]).join(','),
            component);
      }
      for (final param in p0.parameters) {
        if (Processor.error) {
          Processor.error = false;
        }
        testParameter(param, p0, ancestor, screen, noteError);
      }
      if (clearList.isNotEmpty) {
        final map = clearList.entries
            .firstWhereOrNull((element) => element.value.contains(p0));
        if (map != null) {
          map.value.remove(p0);
          if (map.value.isEmpty) {
            for (final key in removeVars[map.key]!)
              processor.variables.remove(key);
            removeVars.remove(map.key);
            clearList.remove(map.key);
          }
        }
      }
      return false;
    });
    disableError = false;
    Processor.checkOnlyConfig = null;
    return valid ? null : ValidationErrorReport(errorLines, count);
  }

  void testParameter(Parameter param, Component p0, Component root,
      Viewable? screen, noteError) {
    final processor = p0.parentProcessor(screen, root) ?? paramProcessor;

    if (param is SimpleParameter) {
      final code = param.compiler.code;
      param.process(code, processor: processor);
      noteError(code, p0);
    } else if (param is BooleanParameter) {
      final code = CodeOperations.trim(param.compiler.code)!;
      processor.process(code,
          config: const ProcessorConfig(unmodifiable: true));
      noteError(code, p0);
    } else if (param is ComplexParameter) {
      param.params.forEach((element) {
        testParameter(element, p0, root, screen, noteError);
      });
    } else if (param is ChoiceParameter) {
      param.options.forEach((element) {
        testParameter(element, p0, root, screen, noteError);
      });
    } else if (param is ListParameter) {
      param.params.forEach((element) {
        testParameter(element, p0, root, screen, noteError);
      });
    }
  }

  ValidationErrorReport? checkIfCanBeFavourite(
      final Component component, final Component ancestor, Viewable? uiScreen) {
    if (['Expanded', 'Flexible', 'SingleChildScrollView']
        .contains(component.name)) {
      return ValidationErrorReport({}, 0,
          error: 'Can not make ${component.name} as favourite');
    }
    return validateComponent(component, ancestor, uiScreen, [
      project!.scopeName,
      ...project!.screens.map((e) => e.name),
    ]);
  }

  void addToFavourites(final Component component) async {
    emit(ComponentOperationLoadingState());
    final List<CustomComponent> customs = [];
    component.forEachWithClones((p0) {
      if (p0 is CustomComponent &&
          customs.firstWhereOrNull((element) => element.name == p0.name) ==
              null) {
        customs.add(p0);
      }
      return false;
    });
    final componentCopy = component.clone(null, deepClone: true, connect: false)
      ..setId = component.id
      ..boundary = component.boundary;
    componentCopy.forEachWithClones((p0) {
      p0.parameters.forEach((element) {
        if (element is UsableParam) {
          if ((element as UsableParam).usableName != null) {
            if ((element as UsableParam).reused) {
              element.cloneOf((element as UsableParam).usedParameter!, false);
            }
            (element as UsableParam).usableName = null;
          }
        }
      });
      return false;
    });
    final model = FavouriteModel(
      componentCopy,
      customs,
      DateTime.now(),
      projectId: project!.id,
      userId: project!.userId,
    );
    if (collection.favouriteList.isNotEmpty) {
      collection.favouriteList.insert(0, model);
    } else {
      collection.favouriteList.add(model);
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
    model.component.boundary = Rect.fromLTWH(0, 0, width, height);
    try {
      await waitForConnectivity();

      await dataBridge.addToFavourites(_userSession.user.userId!, model);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
    emit(ComponentFavouriteListUpdatedState());
  }

  void removeModelFromFavourites(final FavouriteModel model) async {
    emit(ComponentOperationLoadingState());
    try {
      await waitForConnectivity();
      for (final favouriteModel in collection.favouriteList) {
        if (favouriteModel.id == model.id) {
          collection.favouriteList.remove(favouriteModel);
          await dataBridge.removeFromFavourites(
              project!.userId, model.id ?? '');
          break;
        }
      }
      emit(ComponentFavouriteListUpdatedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void removeFromFavourites(final Component component) async {
    emit(ComponentOperationLoadingState());

    try {
      await waitForConnectivity();
      for (final model in collection.favouriteList) {
        if (model.id == model.id) {
          collection.favouriteList.remove(model);
          await dataBridge.removeFromFavourites(
              project!.userId, model.id ?? '');
          break;
        }
      }
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
            (component as CustomComponent).rootComponent == null) ||
        (customNamed != null &&
            (component as CustomNamedHolder).childMap[customNamed] == null);
  }

  void removeAllComponent(Component component, Component ancestor,
      {bool clear = true}) {
    if (ancestor is CustomComponent && component.parent == null) {
      ancestor.rootComponent = null;
      if (clear) {
        switch (component.type) {
          case 1:
            break;
          case 2:
            (component as MultiHolder).children.clear();
            break;
          case 3:
            (component as Holder).updateChild(null);
            break;
        }
      }
      return;
    }
    if (component == ancestor) {
      selectionCubit.selected.viewable?.rootComponent = null;
      creationCubit.changedComponent(ancestor: ancestor);
      return;
    }
    final parent = component.parent!;
    if (clear) {
      if (component.type == 2) {
        (component as MultiHolder).children.clear();
      } else if (component.type == 4) {
        (component as CustomNamedHolder).childMap.clear();
        component.childrenMap.clear();
      }
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
    // if (ancestor is CustomComponent) {
    //   refreshCustomComponents(ancestor);
    // }
  }

  Future<void> updateDeviceSelection(String name) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.updateDeviceSelection(project!.userId, project!, name);
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
      await dataBridge.addVariables(project!.userId, project!, [variableModel]);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addVariables(List<VariableModel> variables) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      for (final variable in variables) {
        project!.processor.variables[variable.name] = variable;
      }
      await dataBridge.addVariables(project!.userId, project!, variables);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addVariableForScreen(VariableModel variableModel) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      final screen = selectionCubit.selected.viewable;
      selectionCubit.selected.viewable?.variables[variableModel.name] =
          variableModel;
      if (screen is Screen) {
        await dataBridge.addVariableForScreen(
            project!.userId, project!, variableModel, screen);
      } else {
        await dataBridge.updateVariableForCustomComponent(
            project!.userId, project!, screen as CustomComponent);
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateProjectSettings() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.updateProjectSettings(project!);
      emit(OperationProjectSettingUpdatedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> addGlobalComponent(GlobalComponentModel model,
      {String? id}) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.addGlobalComponent(id, model);
      if (id != null) {
        componentList.removeWhere((element) => element.id == id);
      }
      componentList.add(model);
      emit(ComponentOperationComponentsLoadedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> removeGlobalComponent(String id) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.removeGlobalComponent(id);
      componentList.removeWhere((model) => model.id == id);
      emit(ComponentOperationComponentsLoadedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  // Future<void> addModel(final LocalModel model) async {
  //   try {
  //     emit(ComponentOperationLoadingState());
  //     await waitForConnectivity();
  //     if (selectionCubit.selected.screen! is Screen) {
  //       await dataBridge.addModel(project!.userId, project!, model, selectionCubit.selected.screen! as Screen);
  //     }
  //     emit(ComponentOperationInitial());
  //   } on Exception catch (e) {
  //     emit(ComponentOperationErrorState(e.toString()));
  //   }
  // }

  Future<void> updateModels() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.updateModels(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateVariable() async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.updateVariable(project!.userId, project!);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateScreenVariable(Viewable screen) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      if (screen is Screen) {
        await dataBridge.updateUIScreenVariable(screen);
      } else {
        await dataBridge.updateVariableForCustomComponent(
            project!.userId, project!, screen as CustomComponent);
      }
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> updateCustomVariable(final CustomComponent component) async {
    try {
      emit(ComponentOperationLoadingState());
      await waitForConnectivity();
      await dataBridge.updateVariableForCustomComponent(
          project!.userId, project!, component);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  Future<void> saveCustomComponent(CustomComponent component) async {
    try {
      emit(ComponentUpdatedState());
      await waitForConnectivity();
      emit(ComponentOperationLoadingState());
      await dataBridge.addCustomComponent(project!.userId, project!, component);
      emit(CustomComponentUpdatedState());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void duplicateComponentOperation(BuildContext context, Component component,
      Component ancestor, String? named) {
    final viewable = ViewableProvider.maybeOf(context)!;
    reversibleComponentOperation(viewable, () {
      final duplicated = duplicateComponent(component, ancestor, named);
      emit(ComponentUpdatedState());
      creationCubit.changedComponent(ancestor: ancestor);
      if (duplicated != null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          selectionCubit.changeComponentSelection(ComponentSelectionModel(
            [duplicated],
            [duplicated],
            duplicated,
            duplicated,
            ancestor,
            viewable: viewable,
          ));
        });
      }
    }, ancestor);
  }

  void arrangeComponentOperation(
    BuildContext context,
    Component component,
    int index,
    int newIndex,
    Component ancestor, {
    required ComponentParameter? parameter,
    required String? named,
  }) {
    revertWork.add([index, newIndex], () {
      arrangeComponent(context, component, index, newIndex, ancestor,
          parameter: parameter, named: named);
    }, (p0) {
      arrangeComponent(context, component, p0[1], p0[0], ancestor,
          parameter: parameter, named: named);
    });
  }

  void addCustomComponentFromFavourite(FavouriteModel object) {
    if (object.component is CustomComponent &&
        project!.customComponents
                .firstWhereOrNull((e) => e.name == object.component.name) ==
            null) {
      project!.customComponents.add(object.component as CustomComponent);
      saveCustomComponent(object.component as CustomComponent);
    }
    for (final component in object.components) {
      if (project!.customComponents
              .firstWhereOrNull((e) => e.name == component.name) ==
          null) {
        project!.customComponents.add(component);
        saveCustomComponent(component);
      }
    }
  }

  Component favouriteInComponent(FavouriteModel object) {
    final Component temp;
    if (object.component is CustomComponent) {
      final sameCustom = project!.customComponents
          .firstWhereOrNull((element) => element.name == object.component.name);
      if (sameCustom != null) {
        temp = sameCustom.createInstance(null);
      } else {
        temp = (object.component as CustomComponent).createInstance(null);
      }
    } else {
      temp = object.component.clone(null, connect: false, deepClone: true);
    }
    addCustomComponentFromFavourite(object);
    return temp;
  }

  void performAddOperation(BuildContext context, Component component,
      Component comp, Component ancestor,
      {required bool componentParameterOperation,
      ComponentParameter? componentParameter,
      String? customNamed,
      required bool undo}) {
    reversibleComponentOperation(ViewableProvider.maybeOf(context)!, () async {
      await addOperation(
        context,
        component,
        comp,
        ancestor,
        componentParameterOperation: componentParameterOperation,
        componentParameter: componentParameter,
        customNamed: customNamed,
        undo: true,
      );
      context
          .read<StateManagementBloc>()
          .add(StateManagementRefreshEvent(component.id, RuntimeMode.edit));
      updateState(ancestor);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        selectionCubit.changeComponentSelection(ComponentSelectionModel.unique(
            comp, ancestor,
            screen: ViewableProvider.maybeOf(context)));
      });
    }, ancestor);
  }

  void renameScreen(Screen screen, String name) async {
    try {
      await waitForConnectivity();
      screen.name = name;
      emit(ComponentOperationScreensUpdatedState());
      emit(ComponentOperationLoadingState());
      await dataBridge.updateScreenValue(screen, 'name', name);
      emit(ComponentOperationInitial());
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }

  void updateProjectThumbnail(FVBProject project, Uint8List image) async {
    try {
      await waitForConnectivity();
      await dataBridge.updateProjectThumbnail(project, image);
    } on Exception catch (e) {
      emit(ComponentOperationErrorState(e.toString()));
    }
  }
}

class ValidationErrorReport {
  final Map<Component, String> componentError;
  final int errorCount;
  final String? error;

  ValidationErrorReport(this.componentError, this.errorCount, {this.error});
}
