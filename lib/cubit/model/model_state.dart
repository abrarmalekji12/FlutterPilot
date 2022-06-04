part of 'model_cubit.dart';

@immutable
abstract class ModelState {}

class ModelInitial extends ModelState {}

class ModelChangedState extends ModelState {
  final LocalModel localModel;
  final bool add;
  ModelChangedState(this.localModel, {this.add = false});
}
