import 'package:bloc/bloc.dart';
import '../../common/logger.dart';
import 'package:meta/meta.dart';

import '../../models/component_model.dart';

part 'component_selection_state.dart';

class ComponentSelectionCubit extends Cubit<ComponentSelectionState> {
  late Component currentSelected;
  late Component currentSelectedRoot;

  ComponentSelectionCubit() : super(ComponentSelectionInitial());

  void init(Component currentSelected,  Component currentSelectedRoot){
    this.currentSelected=currentSelected;
    this.currentSelectedRoot=currentSelectedRoot;
  }
  void changeComponentSelection(Component component, {required Component root}) {
    if (currentSelected != component) {
      currentSelected = component;
      currentSelectedRoot = root;
      logger('==== ComponentSelectionCubit ** changeComponentSelection == ${component.name} ${root.name}');
      emit(ComponentSelectionChange());
    }
  }
}
