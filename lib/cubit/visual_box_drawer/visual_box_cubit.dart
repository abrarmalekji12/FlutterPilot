import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../common/analyzer/analyzer.dart';
import '../../screen_model.dart';
import '../../ui/boundary_widget.dart';
import '../../ui/visual_model.dart';

part 'visual_box_state.dart';

class VisualBoxCubit extends Cubit<VisualBoxState> {
  String? errorMessage;
  final Map<ScreenConfig, List<AnalyzerError>> analysisErrors = {};
  VisualBoxCubit() : super(VisualBoxInitial());

  void visualUpdated(Viewable screen) {
    emit(VisualBoxUpdatedState(screen));
  }

  void visualHoverUpdated(final List<Boundary> boundaries, Viewable screen) {
    emit(VisualBoxHoverUpdatedState(boundaries, screen));
  }

  void addAnalyzerError(
      ScreenConfig config, Viewable screen, List<AnalyzerError> errors) {
    if (analysisErrors.containsKey(config)) {
      if (analysisErrors[config]!.isNotEmpty) {
        analysisErrors[config]!
            .removeWhere((element) => element.screen == screen);
      }
      analysisErrors[config]!.addAll(errors);
    } else {
      analysisErrors[config] = errors;
    }
  }

  void updateError() {
    emit(VisualBoxUpdatedState(null));
  }

  void enableError(String message) {
    errorMessage = message;
    emit(VisualBoxUpdatedState(null));
  }
}
