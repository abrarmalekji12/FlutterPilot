import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'sliding_property_event.dart';
part 'sliding_property_state.dart';

class SlidingPropertyBloc
    extends Bloc<SlidingPropertyEvent, SlidingPropertyState> {
  double value = 1;
  SlidingPropertyBloc() : super(SlidingPropertyInitial()) {
    on<SlidingPropertyEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<SlidingPropertyChange>((event, emit) {
      value = event.value;
      emit(SlidingPropertyChangeState(value: value));
    });
  }
}
