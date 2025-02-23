import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/actions/action_model.dart';
import '../../models/project_model.dart';
import '../../ui/boundary_widget.dart';

part 'stack_action_state.dart';

enum StackOperation { push, replace, dialog, addOverlay, pop }

abstract class FVBRoute {
  final Viewable viewable;

  FVBRoute(this.viewable);
}

class FVBPageRoute extends FVBRoute {
  FVBPageRoute(super.screen);
}

class FVBDialogRoute extends FVBRoute {
  FVBDialogRoute(super.viewable);
}

class FVBOverlayRoute extends FVBRoute {
  FVBOverlayRoute(super.viewable);
}

class StackActionCubit extends Cubit<StackActionState> {
  final List<ActionModel> models = [];
  final List<FVBRoute> navigationStack = [];

  StackActionCubit() : super(StackActionInitial());

  void showSimpleDialog(final ShowDialogInStackAction model) {
    models.add(model);
    emit(StackUpdatedState());
  }

  void showCustomSimpleDialog(final ShowCustomDialogInStackAction model) {
    models.add(model);
    emit(StackUpdatedState());
  }

  void back() {
    if (models.isNotEmpty) {
      models.removeAt(models.length - 1);
      emit(StackUpdatedState());
    }
  }

  void update() {
    emit(StackUpdatedState());
  }

  void reset() {
    navigationStack.clear();
    emit(StackResetState());
  }

  void stackOperation(final StackOperation operation, {Viewable? screen}) {
    switch (operation) {
      case StackOperation.push:
        if (screen != null) navigationStack.add(FVBPageRoute(screen as Screen));
        break;
      case StackOperation.replace:
        if (screen != null) navigationStack.add(FVBPageRoute(screen as Screen));
        break;
      case StackOperation.addOverlay:
        if (screen != null) navigationStack.add(FVBOverlayRoute(screen));
        break;

      case StackOperation.dialog:
        if (screen != null) navigationStack.add(FVBDialogRoute(screen));
        break;
      case StackOperation.pop:
        if (navigationStack.isEmpty) {
          throw Exception('Navigation Stack is Empty !! ');
        } else {
          emit(StackClearState());
          return;
        }
    }
  }
}
