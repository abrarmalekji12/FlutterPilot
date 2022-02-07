class FunctionModel<T> {
  final String name;
  final T Function(List<dynamic>) perform;
  final String functionCode;
  FunctionModel(this.name, this.perform,this.functionCode);
}
