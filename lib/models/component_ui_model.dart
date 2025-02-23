import 'package:flutter/cupertino.dart';
import 'parameter_model.dart';

class SimpleParameterController {
  final SimpleParameter simpleParameter;
  final TextEditingController controller = TextEditingController();
  SimpleParameterController(this.simpleParameter);
}
