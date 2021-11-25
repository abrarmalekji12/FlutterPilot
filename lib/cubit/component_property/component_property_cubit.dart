import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'component_property_state.dart';

class ComponentPropertyCubit extends Cubit<ComponentPropertyState> {
  ComponentPropertyCubit() : super(ComponentPropertyInitial());

  void changedProperty(){
    emit(ComponentPropertyChangeState());
  }
}
