import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../component_list.dart';
import '../../models/component_model.dart';
import '../../models/component_selection.dart';

part 'component_selection_state.dart';

class ComponentSelectionCubit extends Cubit<ComponentSelectionState> {
  late ComponentSelectionModel currentSelected;
  Component? lastTapped;

  ComponentSelectionCubit() : super(ComponentSelectionInitial());

  Component get currentSelectedRoot => currentSelected.root;

  void init(
    ComponentSelectionModel currentSelected,
  ) {
    this.currentSelected = currentSelected;
  }

  void changeComponentSelection(ComponentSelectionModel component,
      {bool scroll = true}) {
    if (currentSelected != component) {
      currentSelected = component;
      // logger('==== ComponentSelectionCubit ** changeComponentSelection == ${component.name} ${root.name}');
      emit(ComponentSelectionChange(scroll: scroll));
    }
  }

  bool isSelectedInTree(Component component) {
    return currentSelected.treeSelection.contains(component);
  }
}
