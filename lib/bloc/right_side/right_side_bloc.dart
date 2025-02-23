import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

part 'right_side_event.dart';
part 'right_side_state.dart';

enum RightSide {
  property('Property', Icons.tune_outlined),
  // navigation('Navigation',Icons.navigation_outlined),

  models('Models', Icons.data_object_sharp),
  variables('Variables', Icons.abc_outlined);
  // api('Apis', Icons.api_rounded);
  // Files('Files', Icons.folder_outlined);

  final String name;
  final IconData icon;
  const RightSide(this.name, this.icon);
}

class RightSideBloc extends Bloc<RightSideEvent, RightSideState> {
  RightSide rightSide = RightSide.property;
  RightSideBloc() : super(RightSideInitial()) {
    on<RightSideEvent>((event, emit) {});
    on<RightSideUpdateEvent>(_onRightSideUpdate);
  }

  void _onRightSideUpdate(
      RightSideUpdateEvent event, Emitter<RightSideState> emit) {
    rightSide = event.side;
    emit(RightSideUpdatedState());
  }
}
