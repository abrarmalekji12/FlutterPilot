
import '../../code_to_component.dart';
import 'code_processor.dart';

class ArgumentProcessor {
  ArgumentProcessor();

  static List<dynamic> process(final CodeProcessor processor,List<String> argumentData,List<FVBArgument> arguments) {
    List<dynamic> processedArguments = List.filled(arguments.length, null);
    Map<String,dynamic> optionArgs={};
    for(final argument in argumentData){
     final split=CodeOperations.splitBy(argument, splitBy: ':');
     if(split.length==2) {
       optionArgs[split[0]] = split[1];
     }
    }
    for (int i = 0; i < arguments.length; i++) {
      if(arguments[i].type==FVBArgumentType.placed){
        processedArguments[i]=processor.process(argumentData[i]);
      }
      else if(optionArgs[arguments[i].name]!=null){
        processedArguments[i]=processor.process(optionArgs[arguments[i].name]);
      }
    }
    return processedArguments;
  }
}