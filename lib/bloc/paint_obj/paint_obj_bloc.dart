import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../components/component_impl.dart';
import '../../cubit/component_selection/component_selection_cubit.dart';
import '../../runtime_provider.dart';
import '../../ui/paint_tools/paint_tools.dart';
import '../state_management/state_management_bloc.dart';

part 'paint_obj_event.dart';
part 'paint_obj_state.dart';

class PaintObjBloc extends Bloc<PaintObjEvent, PaintObjState> {
  FVBPaintObj? paintObj;
  final StateManagementBloc _stateManagementBloc;
  final SelectionCubit _selectionCubit;

  PaintObjBloc(this._stateManagementBloc, this._selectionCubit)
      : super(PaintObjInitial()) {
    on<PaintObjEvent>((event, emit) {});
    on<RemovePaintObjEvent>(_removePaintObj);

    on<UpdatePaintObjEvent>((event, emit) {
      if (event.save) {
        final comp = _selectionCubit.selected.propertySelection;
        if (comp is FVBPainter) {
          _stateManagementBloc
              .add(StateManagementUpdateEvent(comp, RuntimeMode.edit));
        }
      }
      emit(PaintObjUpdateState(event.obj, refreshField: event.refreshField));
    });
    on<UpdatePaintObjSelectionEvent>((event, emit) {
      paintObj = event.obj;
      emit(PaintObjSelectionUpdatedState(event.obj));
    });
  }

  FutureOr<void> _removePaintObj(
      RemovePaintObjEvent event, Emitter<PaintObjState> emit) {
    (_selectionCubit.selected.intendedSelection as CCustomPaint)
        .paintObjects
        .removeWhere((element) => element.id == paintObj?.id);
    if ((_selectionCubit.selected.intendedSelection as CCustomPaint)
        .paintObjects
        .isNotEmpty) {
      paintObj = (_selectionCubit.selected.intendedSelection as CCustomPaint)
          .paintObjects
          .first;
    } else {
      paintObj = null;
    }
    emit(PaintObjSelectionUpdatedState(paintObj));
  }
}
