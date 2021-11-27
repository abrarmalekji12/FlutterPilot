import 'package:flutter/cupertino.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/parameter_model.dart';

class SimpleParameterController{
  final SimpleParameter simpleParameter;
  final TextEditingController controller=TextEditingController();
  SimpleParameterController(this.simpleParameter);
}