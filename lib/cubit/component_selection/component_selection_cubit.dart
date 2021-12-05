import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../component_model.dart';

part 'component_selection_state.dart';

class ComponentSelectionCubit extends Cubit<ComponentSelectionState> {
  Component currentSelected;
  Component currentSelectedRoot;

  ComponentSelectionCubit({
    required this.currentSelected,
    required this.currentSelectedRoot
  }) : super(ComponentSelectionInitial());

  void changeComponentSelection(Component component, {required Component root}) {
    if (currentSelected != component) {
      currentSelected = component;
      currentSelectedRoot = root;
      emit(ComponentSelectionChange());
    }
  }
}
