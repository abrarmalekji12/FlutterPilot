class VariableModel{
  String name;
  double value;
  bool runtimeAssigned;
  String? description;
  String? assignmentCode;
  VariableModel(this.name,this.value,this.runtimeAssigned,this.description,{this.assignmentCode});
}