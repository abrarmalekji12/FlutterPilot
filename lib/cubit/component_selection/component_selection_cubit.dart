import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../component_model.dart';

part 'component_selection_state.dart';

class ComponentSelectionCubit extends Cubit<ComponentSelectionState> {
  Component currentSelected;

  ComponentSelectionCubit({required this.currentSelected})
      : super(ComponentSelectionInitial());

  void changeComponentSelection(Component component) {
    if (currentSelected != component) {
      currentSelected = component;
      emit(ComponentSelectionChange());
    }
  }
}
