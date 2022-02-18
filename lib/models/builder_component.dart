import 'package:flutter/src/widgets/framework.dart';

import 'component_model.dart';
import 'local_model.dart';
import 'parameter_model.dart';

abstract class BuilderComponent extends Component{
  Component? root;
  List<LocalModel> models=[];
  BuilderComponent(String name, List<Parameter> parameters) : super(name, parameters);
  // Widget builder(BuildContext context, int index){
  //   return
  // }
}