class FunctionModel<T> {
  final String name;
  final T Function(List<dynamic>) perform;
  final String? functionCode;
  final String description;
  FunctionModel(this.name, this.perform, {required this.description,this.functionCode});
}
