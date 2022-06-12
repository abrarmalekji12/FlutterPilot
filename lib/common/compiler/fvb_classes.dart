import '../../ui/models_view.dart';
import 'code_processor.dart';
import 'package:http/http.dart' as http;

class FVBModuleClasses {
  static Map<String, FVBClass> fvbClasses = {
    'TextField': FVBClass('TextField', {
      'setText': FVBFunction('setText', null, [FVBArgument('text')]),
      'clear': FVBFunction('clear', '', []),
    }, {
      'text': FVBVariable('text', DataType.string),
    }),
    'Future': FVBClass('Future', {
      'then': FVBFunction('then', 'onValue=value;', [FVBArgument('value')]),
      'onError':
          FVBFunction('onError', 'onError=error;', [FVBArgument('error')]),
    }, {
      'value': FVBVariable('value', DataType.dynamic),
      'onValue': FVBVariable('onValue', DataType.fvbFunction),
      'onError': FVBVariable('onError', DataType.fvbFunction),
    }),
    'Api': FVBClass('Api', {
      'get': FVBFunction('get', null, [FVBArgument('url')])
        ..dartCall = (arguments) async {
          return (await http.get(arguments[0])).body;
        },
    }, {}),
    'Duration': FVBClass('Duration', {
      'Duration': FVBFunction('Duration', '', [
        FVBArgument('this.milliseconds'),
      ]),
    }, {
      'milliseconds': FVBVariable('milliseconds', DataType.int),
    }),
  };

  FVBModuleClasses() {}
}
