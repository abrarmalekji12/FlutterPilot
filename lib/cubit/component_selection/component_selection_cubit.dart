
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/component_model.dart';
import '../../models/component_selection.dart';

part 'component_selection_state.dart';

class ComponentSelectionCubit extends Cubit<ComponentSelectionState> {
  late ComponentSelectionModel currentSelected;
  late Component currentSelectedRoot;
  Component? lastTapped;

  ComponentSelectionCubit() : super(ComponentSelectionInitial());

  void init(ComponentSelectionModel currentSelected,  Component currentSelectedRoot){
    this.currentSelected=currentSelected;
    this.currentSelectedRoot=currentSelectedRoot;
  }
  void changeComponentSelection(ComponentSelectionModel component, {required Component root,bool scroll=true}) {
    if (currentSelected != component) {
      currentSelected = component;
      currentSelectedRoot = root;
      // logger('==== ComponentSelectionCubit ** changeComponentSelection == ${component.name} ${root.name}');
      emit(ComponentSelectionChange(scroll: scroll));
    }
  }
  bool isSelectedInTree(Component component){
    return currentSelected.treeSelection.contains(component);
  }
}
