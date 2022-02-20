import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../models/local_model.dart';

part 'model_state.dart';

class ModelCubit extends Cubit<ModelState> {
  ModelCubit() : super(ModelInitial());

  void changed(final LocalModel model,{bool add=false}){
    emit(ModelChangedState(model,add: add));
  }
}
