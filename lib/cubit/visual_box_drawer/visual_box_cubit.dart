import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../ui/visual_model.dart';

part 'visual_box_state.dart';

class VisualBoxCubit extends Cubit<VisualBoxState> {
  String? errorMessage;
  VisualBoxCubit() : super(VisualBoxInitial());

  void visualUpdated() {
    emit(VisualBoxUpdatedState());
  }

  void visualHoverUpdated(final List<Boundary> boundaries) {
    emit(VisualBoxHoverUpdatedState(boundaries));
  }

  void enableError(String message) {
    errorMessage = message;
    emit(VisualBoxUpdatedState());
  }
}
