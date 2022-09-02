
import 'fvb_class.dart';
import 'fvb_function_variables.dart';

class FVBFile {
  List<FVBClass> classes;
  List<FVBFunction> functions;
  List<FVBVariable> variables;
  FVBFile(this.classes,this.functions,this.variables);
}
class FVBDirectory{
  List<FVBFile> files;
  FVBDirectory(this.files);
}