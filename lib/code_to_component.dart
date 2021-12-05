import 'package:flutter_builder/component_list.dart';
import 'package:flutter_builder/component_model.dart';
import 'package:flutter_builder/parameter_model.dart';

// abstract class CodeToComponent {
//   static Component fromCode(String code) {
//     final split1=code.split('(');
//     final split2=split1[1].split(')');
//     final component=componentList[split1[0]]!();
//     for(final paramCode in split2[0].split(',')){
//       final paramNamed=paramCode.contains(':')?paramCode.split(':'):null;
//
//     }
//   }
// }
//
// abstract class CodeToParameter{
//   static Parameter fromCode(String code){
//
//   }
// }