import 'package:flutter_builder/common/compiler/code_processor.dart';

import '../../models/local_model.dart';
import 'fvb_converter.dart';
import 'fvb_function_variables.dart';

class FVBClass {
  final String name;
  final Map<String, FVBFunction> fvbFunctions;
  final Map<String, FVBVariable Function()> fvbVariables;
  final Map<String, FVBFunction>? fvbStaticFunctions;
  final Map<String, FVBVariable>? fvbStaticVariables;
  final FVBConverter? converter;
  final List<String> generics;
  List<FVBClass> superclasses = [];

  FVBClass(this.name, this.fvbFunctions, this.fvbVariables,
      {this.fvbStaticVariables,
        this.converter,
        this.fvbStaticFunctions,
        this.generics = const [],
        CodeProcessor? parent});

  @override
  toString() => name;

  factory FVBClass.create(String name,
      {Map<String, FVBVariable Function()>? vars,
        List<FVBFunction>? funs,
        List<FVBVariable>? staticVars,
        List<FVBFunction>? staticFuns,
        FVBConverter? converter}) {
    return FVBClass(
      name,
      Map.fromEntries(funs?.map((e) => MapEntry(e.name, e)) ?? []),
      vars ?? {},
      fvbStaticVariables:
      Map.fromEntries(staticVars?.map((e) => MapEntry(e.name, e)) ?? []),
      fvbStaticFunctions:
      Map.fromEntries(staticFuns?.map((e) => MapEntry(e.name, e)) ?? []),
      converter: converter,
    );
  }

  FVBFunction? get getDefaultConstructor {
    return fvbFunctions[name];
  }

  Iterable<FVBFunction> get getNamedConstructor {
    return fvbFunctions.values
        .where((element) => element.name.startsWith('$name.'));
  }

  FVBInstance createInstance(
      final CodeProcessor parent, final List<dynamic> arguments,
      {final String? constructorName, final List<DataType>? generics}) {
    final constructor = constructorName ?? name;
    final isFactory = fvbFunctions[constructor]?.isFactory ?? false;
    if (isFactory) {
      return fvbFunctions[constructor]!.execute(parent, null, arguments);
    }
    final instance =
    FVBInstance(this, parent: parent, generics: generics ?? []);
    if (fvbFunctions.containsKey(constructor)) {
      instance.executeFunction(constructor, arguments + [instance]);
    } else if (constructorName != null) {
      throw Exception('No constructor named $constructor in $name');
    }
    return instance;
  }

  FVBCacheValue getValue(final String variable, final CodeProcessor processor) {
    if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(variable)) {
      if (fvbStaticVariables![variable]!.getCall != null) {
        return FVBCacheValue(
            fvbStaticVariables![variable]!.getCall!(null, processor),
            fvbStaticVariables![variable]!.dataType);
      }
      return FVBCacheValue(fvbStaticVariables![variable]!.value,
          fvbStaticVariables![variable]!.dataType);
    } else if (fvbStaticFunctions != null &&
        fvbStaticFunctions!.containsKey(variable)) {
      return FVBCacheValue(
          fvbStaticFunctions![variable]!, DataType.fvbFunction);
    }
    return FVBCacheValue(null, DataType.fvbNull);
  }

  void setValue(final String variable, dynamic value) {
    if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(variable)) {
      fvbStaticVariables![variable]!.value = value;
    } else if (fvbStaticFunctions != null &&
        fvbStaticFunctions!.containsKey(variable)) {
      fvbStaticVariables![variable]!.value = value;
    }
  }

  FVBFunction? getFunction(CodeProcessor processor, String name) {
    final FVBFunction? function;
    if (fvbStaticFunctions != null && fvbStaticFunctions!.containsKey(name)) {
      function = fvbStaticFunctions![name];
    } else if (fvbStaticVariables != null &&
        fvbStaticVariables!.containsKey(name)) {
      function = fvbStaticVariables![name]!.value;
    } else {
      throw Exception('Function $name not found in class ${this.name}');
    }
    return function;
  }

  executeFunction(CodeProcessor parent, String name, List<dynamic> arguments) {
    final output = getFunction(parent, name)?.execute(parent, null, arguments);
    return output;
  }
}

class FVBModel extends FVBClass {
  FVBModel.create(LocalModel model)
      : super(
    model.name,
    {},
    model.variables
        .asMap()
        .map((key, e) => MapEntry(e.name, () => e.toVar)),
  );
}

class FVBInstance {
  final FVBClass fvbClass;
  late final CodeProcessor processor;
  final List<DataType> generics;

  FVBInstance(this.fvbClass,
      {CodeProcessor? parent, this.generics = const []}) {
    processor = CodeProcessor.build(name: fvbClass.name, processor: parent)
      ..functions.addAll(fvbClass.fvbFunctions)
      ..variables.addAll(fvbClass.fvbVariables.map(
            (key, value) => MapEntry(key, value.call()),
      ));
  }

  toDart() {
    if (fvbClass.converter == null) {
      return variables['_dart']!.value;
    }
    return fvbClass.converter?.toDart(this);
  }

  Map<String, FVBVariable> get variables => processor.variables;

  Map<String, FVBFunction> get functions => processor.functions;

  @override
  Type get runtimeType => CustomType(fvbClass.name);

  FVBFunction? getFunction(CodeProcessor processor, String name) {
    final FVBFunction? function;
    if (fvbClass.fvbFunctions.containsKey(name)) {
      function = fvbClass.fvbFunctions[name];
    } else if (variables.containsKey(name)) {
      function = variables[name]!.value;
    } else {
      throw Exception('Function $name not found in class ${fvbClass.name}');
    }
    return function;
  }

  executeFunction(String name, List<dynamic> arguments) {
    final function = getFunction(processor, name)!;
    if (function.code == null && function.dartCall == null) {
      return fvbClass.converter!.fromDart(
          name,
          arguments
              .map(
                (e) => fvbClass.converter!.convert(e),
          )
              .toList(growable: false));
    }
    final output = function.execute(processor, this, arguments);
    return output;
  }
}
