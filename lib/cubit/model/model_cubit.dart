import 'package:bloc/bloc.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';
import 'package:meta/meta.dart';

import '../component_operation/operation_cubit.dart';

part 'model_state.dart';

class ModelCubit extends Cubit<ModelState> {
  final OperationCubit componentOperationCubit;
  ModelCubit(this.componentOperationCubit) : super(ModelInitial());

  void changed(FVBModelClass model) async {
    componentOperationCubit.updateModels();
    model.createConstructor();
    emit(ModelChangedState());
  }
}
