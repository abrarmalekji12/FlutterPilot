import 'package:fvb_processor/compiler/code_processor.dart';

class FunctionModel<T> {
  final String name;
  final T Function(List<dynamic>, Processor) perform;
  final String? functionCode;
  final String description;
  FunctionModel(this.name, this.perform,
      {required this.description, this.functionCode});
}
