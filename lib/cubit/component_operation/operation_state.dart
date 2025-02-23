part of 'operation_cubit.dart';

@immutable
abstract class OperationState {}

class ComponentOperationInitial extends OperationState {}

class ComponentOperationScreensUpdatedState extends OperationState {}

class OperationProjectSettingUpdatedState extends OperationState {}

class ComponentOperationTemplateLoadedState extends OperationState {}

class ComponentOperationComponentsLoadedState extends OperationState {}

class ComponentOperationLoadingState extends OperationState {}

class ComponentOperationLoadingFigmaScreensState extends OperationState {}

class ComponentOperationFigmaScreensConvertedState extends OperationState {
  final List<Screen> screens;

  ComponentOperationFigmaScreensConvertedState(this.screens);
}

class ComponentOperationScreenAddingState extends OperationState {}

class ComponentOperationComponentLoadingState extends OperationState {}

class ComponentOperationTemplateUploadingState extends OperationState {}

class CustomComponentVariableUpdatedState extends ComponentUpdatedState {}

class ComponentLoadBytesState extends OperationState {
  ComponentLoadBytesState(this.bytes);

  final Uint8List? bytes;
}

class ComponentFavouriteLoadedState extends OperationState {
  ComponentFavouriteLoadedState();
}

class ComponentOperationErrorState extends OperationState {
  final String msg;
  final ErrorType type;

  ComponentOperationErrorState(this.msg, {this.type = ErrorType.other});
}

class CustomComponentUpdatedState extends OperationState {
  CustomComponentUpdatedState();
}

class ComponentUpdatedState extends OperationState {
  ComponentUpdatedState();
}

class ComponentFavouriteListUpdatedState extends ComponentUpdatedState {
  ComponentFavouriteListUpdatedState();
}

enum ErrorType { network, other }
