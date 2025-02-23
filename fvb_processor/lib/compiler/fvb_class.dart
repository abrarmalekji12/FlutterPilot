import 'package:flutter_builder/common/analyzer/package_analyzer.dart';
import 'package:flutter_builder/common/converter/string_operation.dart';
import 'package:flutter_builder/injector.dart';
import 'package:flutter_builder/models/project_model.dart';
import 'package:flutter_builder/models/variable_model.dart';

import 'argument_processor.dart';
import 'code_processor.dart';
import 'fvb_converter.dart';
import 'fvb_function_variables.dart';

class FVBModelClass extends FVBClass {
  String listName = '';

  FVBModelClass(
    String name, {
    required super.fvbFunctions,
    required super.fvbVariables,
    super.fvbStaticVariables,
    super.converter,
    super.library,
    super.subClassOf,
    super.fvbStaticFunctions,
    super.generics,
  }) : super(name) {
    listName = '${StringOperation.toCamelCase(name, startWithLower: true)}List';
  }

  factory FVBModelClass.create(String name,
          {Map<String, FVBVariable Function()>? vars,
          List<FVBFunction>? funs,
          List<FVBVariable>? staticVars,
          List<FVBFunction>? staticFuns,
          String? library,
          FVBClass? subclassOf,
          FVBConverter? converter}) =>
      FVBModelClass(name,
          fvbFunctions:
              Map.fromEntries(funs?.map((e) => MapEntry(e.name, e)) ?? []),
          fvbVariables: vars ?? {},
          fvbStaticVariables: Map.fromEntries(
              staticVars?.map((e) => MapEntry(e.name, e)) ?? []),
          fvbStaticFunctions: Map.fromEntries(
              staticFuns?.map((e) => MapEntry(e.name, e)) ?? []),
          converter: converter,
          library: library,
          subClassOf: subclassOf);

  String implCode(FVBProject project) => '''
  ${PackageAnalyzer.getPackages(project, null, null)}
  class $name {
  ${fvbVariables.values.map((e) => e()).map((value) => 'final ${DataType.dataTypeToCode(value.dataType)} ${value.name};').join('\n')}
  $name(${fvbVariables.isEmpty ? '' : '{${fvbVariables.keys.map((e) => 'this.$e').join(',')}}'});
  ${fvbFunctions.values.where((element) => element.code?.isNotEmpty ?? false).map((e) => e.implCode).join('\n')}
  
  }
  ''';

  String get fileName => StringOperation.toSnakeCase(name);

  Map<String, dynamic> toJson() {
    return {
      'list_name': listName,
      'name': name,
      'variables':
          fvbVariables.values.map((e) => e().toJson()).toList(growable: false),
      'values': instances
          .map((e) => {
                'var_list': e.variables.values
                    .map((e) => e.value)
                    .toList(growable: false)
              })
          .toList(growable: false),
    };
  }

  factory FVBModelClass.fromJson(
      Map<String, dynamic> data, FVBProject project) {
    final model = FVBModelClass(
      data['name'],
      fvbFunctions: {},
      fvbVariables: (data['variables'] as List).asMap().map((key, value) {
        var variable = FVBVariable.fromJson(value);
        variable.dataType = variable.dataType.copyWith(nullable: true);
        variable = variable.copyWith(nullable: true);
        return MapEntry(value['name'], () => variable.clone());
      }),
    )..listName = data['list_name'];
    model.createConstructor();
    Processor.classes[model.name] = model;
    project.variables[model.listName] = VariableModel(
        model.listName,
        DataType.list(
          DataType.fvbInstance(model.name),
        ),
        value: (data['values'] as List?)
                ?.where((element) =>
                    (element['var_list'] as List).length ==
                    model.fvbVariables.length)
                .map((e) => model.createInstance(
                    project.processor, (e['var_list'] as List),
                    config: const ProcessorConfig()))
                .toList() ??
            [],
        uiAttached: true,
        isFinal: true);
    return model;
  }

  List<FVBInstance> get instances => (List.castFrom<dynamic, FVBInstance>(
      collection.project!.variables[listName]?.value ?? []));

  void createConstructor() {
    final args = fvbVariables.values
        .map((e) => e())
        .map(
          (key) => FVBArgument(
            'this.${key.name}',
            type: FVBArgumentType.optionalNamed,
            dataType: key.dataType,
            nullable: true,
          ),
        )
        .toList();
    fvbFunctions[name] = FVBFunction(name, '', args);
    String toJson(FVBVariable variable) {
      if (variable.dataType.name == 'fvbInstance' &&
          variable.value is FVBInstance &&
          (variable.value as FVBInstance)
              .fvbClass
              .fvbFunctions
              .containsKey('toJson')) {
        return '${variable.name}.toJson()';
      }
      return variable.name;
    }

    final returnCode = '{${fvbVariables.values.map((value) {
      final v = value.call();
      return '"${v.name}":${toJson(v)}';
    }).join(',')}}';
    fvbFunctions['toJson'] = FVBFunction(
      'toJson',
      'return@$returnCode;',
      [],
      dartCode: 'return $returnCode;',
      returnType: DataType.map([DataType.string, DataType.fvbDynamic]),
    );

    final code = args.map((value) {
      if (value.dataType.isFVBInstance &&
          value.dataType.fvbName != 'List' &&
          value.dataType.fvbName != 'Map' &&
          value.dataType.fvbName != 'Timestamp') {
        return '${value.argName}:map["${value.argName}"]!=null?${value.dataType.fvbName}.fromJson(map["${value.argName}"]):null';
      }
      return '${value.argName}:map["${value.argName}"]';
    }).join(',');
    fvbFunctions['$name.fromJson'] = FVBFunction(
        '$name.fromJson',
        'return@$name($code);',
        [
          FVBArgument('map',
              dataType: DataType.map([
                DataType.string,
                DataType.fvbDynamic,
              ]))
        ],
        isFactory: true,
        dartCode: 'return $name($code);');
  }

  set alterName(String name) {}
}

class FVBClass {
  String name;
  final Map<String, FVBFunction> fvbFunctions;
  final Map<String, FVBVariable Function()> fvbVariables;
  final Map<String, FVBFunction>? fvbStaticFunctions;
  final Map<String, FVBVariable>? fvbStaticVariables;
  final FVBConverter? converter;
  final List<String> generics;
  final FVBClass? subClassOf;
  final String? library;
  List<FVBClass> superclasses = [];

  FVBClass(this.name,
      {this.fvbStaticVariables,
      this.converter,
      this.library,
      this.subClassOf,
      this.fvbStaticFunctions,
      required this.fvbFunctions,
      required this.fvbVariables,
      this.generics = const [],
      Processor? parent});

  @override
  toString() => name;

  factory FVBClass.create(String name,
      {Map<String, FVBVariable Function()>? vars,
      List<FVBFunction>? funs,
      List<FVBVariable>? staticVars,
      List<FVBFunction>? staticFuns,
      String? library,
      FVBClass? subclassOf,
      List<String> generics = const [],
      FVBConverter? converter}) {
    return FVBClass(name,
        fvbFunctions:
            Map.fromEntries(funs?.map((e) => MapEntry(e.name, e)) ?? []),
        fvbVariables: vars ?? {},
        fvbStaticVariables:
            Map.fromEntries(staticVars?.map((e) => MapEntry(e.name, e)) ?? []),
        fvbStaticFunctions:
            Map.fromEntries(staticFuns?.map((e) => MapEntry(e.name, e)) ?? []),
        converter: converter,
        library: library,
        generics: generics,
        subClassOf: subclassOf);
  }

  FVBFunction? get getDefaultConstructor {
    return fvbFunctions[name];
  }

  Iterable<FVBFunction> get getNamedConstructor {
    return fvbFunctions.values
        .where((element) => element.name.startsWith('$name.'));
  }

  FVBInstance createInstance(final Processor parent, List<dynamic> arguments,
      {final String? constructorName,
      final List<DataType>? parsedGenerics,
      ProcessorConfig? config}) {
    final constructor = constructorName ?? name;
    final isFactory = fvbFunctions[constructor]?.isFactory ?? false;

    if (isFactory) {
      final factoryOut = fvbFunctions[constructor]!.execute(
          parent, null, arguments,
          config: config ?? const ProcessorConfig());
      if (Processor.error) {
        throw Exception(Processor.errorMessage);
      }

      if (factoryOut == null) {
        throw Exception(
            "can't return null from factory constructor \"$constructor\"");
      } else if (factoryOut is FVBTest && factoryOut.fvbClass == this) {
        return factoryOut.testValue(parent);
      } else if ((factoryOut is! FVBInstance || factoryOut.fvbClass != this) &&
          factoryOut is! FVBTest) {
        throw Exception(
            "Invalid value returned from factory constructor \"$constructor\"");
      }

      return factoryOut;
    }
    final instance = FVBInstance(this,
        parent: parent,
        generics: generics.asMap().map((index, value) => MapEntry(
              value,
              (parsedGenerics?.length ?? 0) > index
                  ? parsedGenerics![index]
                  : DataType.fvbDynamic,
            )));

    if (fvbFunctions.containsKey(constructor)) {
      instance.executeFunction(constructor, arguments + [instance],
          config ?? const ProcessorConfig());
    } else if (constructorName != null) {
      throw Exception('No constructor named $constructor in class "$name"');
    }
    if (Processor.error) {
      throw Exception(Processor.errorMessage);
    }
    return instance;
  }

  FVBCacheValue getValue(final String variable, final Processor processor) {
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
    return FVBCacheValue.kNull;
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

  FVBFunction? getFunction(Processor processor, String name) {
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

  executeFunction(Processor parent, String name, List<dynamic> arguments,
      ProcessorConfig config) {
    final output = getFunction(parent, name)
        ?.execute(parent, null, arguments, config: config);
    return output;
  }

  /// To test method calls in code analysis phase
  void testMethod(int index, String name, FVBTest instance,
      List<String> argumentList, Processor processor, valueStack, config) {
    if (fvbFunctions.containsKey(name)) {
      final fun = fvbFunctions[name]!;
      ArgumentProcessor.process(
          fun, index, processor, argumentList, {}, config);
      // fun.execute(
      //   processor,
      //     instance,
      //   fun.arguments.map((e) => FVBTest(e.dataType, e.nullable)).toList(),
      //   config: config
      // );
      valueStack.push(
        FVBValue(
            value: FVBTest(fun.returnType, fun.canReturnNull),
            dataType: fun.returnType),
      );
    } else {
      throw Exception(
          'Method $name not found in ${instance.dataType.fvbName ?? instance.dataType.name}!');
    }
  }

  void testStaticMethod(int index, String name, FVBTest instance,
      List<String> argumentList, Processor processor, valueStack, config) {
    if (fvbStaticFunctions?.containsKey(name) ?? false) {
      final fun = fvbStaticFunctions![name]!;
      ArgumentProcessor.process(
          fun, index, processor, argumentList, {}, config);
      // fun.execute(
      //   processor,
      //     instance,
      //   fun.arguments.map((e) => FVBTest(e.dataType, e.nullable)).toList(),
      //   config: config
      // );
      valueStack.push(
        FVBValue(
            value: FVBTest(fun.returnType, fun.canReturnNull),
            dataType: fun.returnType),
      );
    } else {
      throw Exception(
          'Method $name not found in ${instance.dataType.fvbName ?? instance.dataType.name}!');
    }
  }
}

// class FVBModel extends FVBClass {
//   FVBModel.create(LocalModel model)
//       : super(
//           model.name,
//           {},
//           model.variables.asMap().map((key, e) => MapEntry(e.name, () => e.toVar)),
//         );
// }

class FVBInstance {
  final FVBClass fvbClass;
  late final Processor processor;
  final Map<String, DataType> generics;

  FVBInstance(this.fvbClass, {Processor? parent, this.generics = const {}}) {
    processor =
        Processor.build(name: fvbClass.name, parent: parent, avoidBinding: true)
          ..functions.addAll(fvbClass.fvbFunctions)
          ..variables.addAll(fvbClass.fvbVariables.map(
            (key, value) => MapEntry(key, value.call()),
          ));
  }

  String defineCode() {
    return fvbClass.getDefaultConstructor?.generate(
            variables.map((key, value) => MapEntry(key, value.value))) ??
        '';
    // return '${fvbClass.name}(${variables.values.map((e) => '${e.}:${LocalModel.valueToCode(e.value)}').join(',')}';
  }

  @override
  String toString() {
    if (Processor.operationType == OperationType.regular) {
      if (functions.containsKey('toString')) {
        return functions['toString']!.execute(null, this, []);
      }

      return 'Instance of ${fvbClass.name}';
    }
    return '';
  }

  toDart() {
    if (fvbClass.name == 'Future') {
      return variables['future']?.value;
    }
    if (fvbClass.converter == null) {
      return variables['_dart']?.value;
    }
    return fvbClass.converter?.toDart(this);
  }

  Map<String, FVBVariable> get variables => processor.variables;

  Map<String, FVBFunction> get functions => processor.functions;

  @override
  Type get runtimeType => CustomType(fvbClass.name);

  FVBFunction? getFunction(Processor processor, String name) {
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

  executeFunction(
      String name, List<dynamic> arguments, ProcessorConfig config) {
    final function = getFunction(processor, name)!;
    if (function.code == null && function.dartCall == null) {
      return fvbClass.converter?.fromDart(
          name,
          arguments
              .map(
                (e) => fvbClass.converter!.convert(e),
              )
              .toList(growable: false));
    }
    final output = function.execute(processor, this, arguments, config: config);
    return output;
  }
}
