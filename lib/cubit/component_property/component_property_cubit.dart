import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/cubit/component_operation/component_operation_cubit.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import '../../component_model.dart';

part 'component_property_state.dart';

class ComponentPropertyCubit extends Cubit<ComponentPropertyState> {
  ComponentPropertyCubit() : super(ComponentPropertyInitial());

  void changedProperty(BuildContext context){
    final component=Provider.of<ComponentOperationCubit>(context,
        listen: false).rootComponent;
    if(component.parent is CustomNamedHolder) {
      emit(ComponentPropertyChangeState(component.parent!));
    }
    else{
      emit(ComponentPropertyChangeState(component));
    }
  }
}
