import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:fvb_processor/compiler/fvb_class.dart';

import '../../code_operations.dart';
import '../../data/remote/common_data_models.dart';
import '../../injector.dart';
import '../../models/local_model.dart';
import '../../models/project_model.dart';
import '../../models/variable_model.dart';
import '../converter/string_operation.dart';

class ApiGroupModel {
  final List<ApiDataModel> apis;
  late Processor processor;

  ApiGroupModel(List<VariableModel> variables, this.apis, FVBProject project) {
    processor = Processor(
        scopeName: 'Api',
        consoleCallback: (value, {List<dynamic>? arguments}) {
          return null;
        },
        onError: (error, _) {},
        parentProcessor: project.processor);
    processor.variables.addAll(
        variables.asMap().map((key, value) => MapEntry(value.name, value)));
  }

  get constants =>
      processor.variables.values.where((element) => element.isFinal);

  get variables =>
      processor.variables.values.where((element) => !element.isFinal);

  Map<String, dynamic> toJson() {
    return {
      'variables': processor.variables.values
          .map((e) => e.toJson())
          .toList(growable: false),
      'api': apis.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory ApiGroupModel.fromJson(
      Map<String, dynamic> json, FVBProject project) {
    final model = ApiGroupModel(
        ((json['variables'] ?? []) as List)
            .map((e) => VariableModel.fromJson(e))
            .toList(),
        [],
        project);
    model.apis.addAll(((json['api'] ?? []) as List)
        .map((e) => ApiDataModel.fromJson(e, model.processor)));
    return model;
  }

  String dioClientCode() {
    return '// Coming Soon';
  }

  String apisCode() {
    /// TODO: UPDATE API RESPONSE MODEL AS PER ACTUAL CODE
    final package = collection.project?.packageName ?? '';
    return '''
   import 'package:dio/dio.dart';
   import 'dart:convert';
   import 'package:${package}/main.dart';
   
     final Dio _dio = Dio();
  
class ApiResponse {
  final String? body;
  final int status;
  final String? error, message;
  final String? statusMessage;
  final Map<String, List<String>>? headers;
  final Map<String, dynamic>? extra;

  ApiResponse(
    this.body,
    this.status, {
    this.error,
    this.headers,
    this.message,
    this.statusMessage,
    this.extra,
  });

  Map<String, dynamic> get bodyMap {
    try {
      return jsonDecode(body ?? '');
    } on Exception catch (e) {}
    return {};
  }
}

    ${processor.variables.values.map((e) => e.code).join('\n')}
    class Apis {
    ${apis.map((e) => 'final ${e.name}=${StringOperation.toCamelCase(e.name)}.singleton();').join('\n')}
    }
    
    final myApis = Apis();
    
    ${apis.map((e) => e.implCode()).join('\n')}
    
     RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

    ''';
  }
}

class ApiSettings {
  ApiSettings();

  Map<String, dynamic> toJson() {
    return {};
  }

  factory ApiSettings.fromJson(Map<String, dynamic> json) {
    return ApiSettings();
  }
}

class HeaderTile {
  String key;
  String value;

  HeaderTile(this.key, this.value);

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  factory HeaderTile.fromJson(Map<String, dynamic> json) {
    return HeaderTile(json['key'], json['value']);
  }
}

class ApiProcessedModel {
  final String baseURL;
  final String method;
  final String name;
  final Map<String, dynamic> header;
  final Map<String, dynamic> body;

  ApiProcessedModel(
      this.name, this.baseURL, this.method, this.header, this.body);
}

/// This will hold details that will be needed for single API, String will hold code not constants;
class ApiDataModel {
  late Processor processor;
  String baseURL;
  String method;
  String name;
  List<HeaderTile> header;
  BodyModel body;
  bool convertToDart;
  ApiSettings apiSettings;
  final List<String> errorList = [];
  FVBClass? convertedClass;

  ApiDataModel(this.name, this.baseURL, this.method, this.header, this.body,
      this.convertToDart, this.apiSettings, Processor parent) {
    processor = Processor(
        scopeName: 'api_${DateTime.now().millisecondsSinceEpoch}',
        consoleCallback: (code, {List<dynamic>? arguments}) {
          return null;
        },
        onError: (error, line) {
          errorList.add(error);
        },
        parentProcessor: parent);
  }

  String implCode() {
    final className = StringOperation.toCamelCase(name, startWithLower: false);
    return '''class $className { 
     static $className? $name;
     $className();
     factory $className.singleton(){
     if($name!=null){
     return $name!; 
     }
     return $name = $className();
     }
   
  
     Future<ApiResponse> fetch(${processor.variables.isNotEmpty ? '{${processor.variables.values.map((value) => '${DataType.dataTypeToCode(value.dataType)} ${value.name} = ${LocalModel.valueToCode(value.value)}').join(',')}}' : ''}) async {
      final String base = '$baseURL';
     final String method = ${LocalModel.valueToCode(method)};
     final Map<String,dynamic> header = ${header.isEmpty ? '{}' : '{${header.map((e) => '${LocalModel.valueToCode(e.key)}:${LocalModel.valueToCode(e.value)}').join(',')}}'};
     final Map<String,dynamic> body = ${body.declareCode()};
     
      final queryParameters = <String, dynamic>{};
      final _result = await _dio.fetch<String>(_setStreamType<String>(
          Options(method: method, headers: header, extra: {})
              .compose(_dio.options, '',
                  queryParameters: queryParameters, data: body)
              .copyWith(baseUrl: base)));
      return ApiResponse(
        _result.data.toString(),
        _result.statusCode ?? -1,
        extra: _result.extra,
        headers: _result.headers.map,
        statusMessage: _result.statusMessage,
      );

     }
     }''';
  }

  Optional<ApiProcessedModel, List<String>> process(
      {List<dynamic>? arguments}) {
    final Map<String, dynamic> _header = {};
    final Map<String, dynamic> _body = {};
    final processor = arguments == null
        ? this.processor
        : this.processor.clone(
            Processor.defaultConsoleCallback, Processor.defaultOnError, false);
    if (arguments != null) {
      for (int i = 0; i < processor.variables.length; i++) {
        if (arguments[i] != null)
          processor.variables.values.elementAt(i).value = arguments[i];
      }
    }
    errorList.clear();
    for (final headerTile in header) {
      if (headerTile.key.isNotEmpty && headerTile.value.isNotEmpty) {
        _header[processor.cleanAndExecute('"${headerTile.key}"')] =
            processor.cleanAndExecute('"${headerTile.value}"');
        if (Processor.error) {
          return Optional.right(errorList);
        }
      }
    }

    if (body is RawBodyModel) {
      final value = processor.cleanAndExecute((body as RawBodyModel).code);
      if (value != null && value is! Map) {
        processor.enableError('Invalid Body ${value}');
        return Optional.right(errorList);
      }
      _body.addAll(Map.from(value ?? {}));
    }
    final String baseURLDecoded = processor.cleanAndExecute('"$baseURL"');
    if (Processor.error) {
      return Optional.right(errorList);
    }
    return Optional.left(
        ApiProcessedModel(name, baseURLDecoded, method, _header, _body));
  }

  Map<String, dynamic> toJson() {
    return {
      'arguments': processor.variables.values
          .map((e) => e.toJson())
          .toList(growable: false),
      'baseURL': baseURL,
      'method': method,
      'name': name,
      'header': header.map((e) => e.toJson()).toList(growable: false),
      'body': body.toJson(),
      'convertToDart': convertToDart,
      'ApiSettings': apiSettings.toJson(),
    };
  }

  @override
  factory ApiDataModel.fromJson(Map<String, dynamic> json, Processor parent) {
    final model = ApiDataModel(
        json['name'],
        json['baseURL'],
        json['method'],
        ((json['header'] ?? []) as List)
            .map(
              (e) => HeaderTile.fromJson(e),
            )
            .toList(),
        BodyModel.fromJson(json['body']),
        json['convertToDart'],
        ApiSettings.fromJson(json['ApiSettings']),
        parent)
      ..processor.variables.addAll(
            ((json['arguments'] ?? []) as List).asMap().map(
                  (key, value) =>
                      MapEntry(value['name'], VariableModel.fromJson(value)),
                ),
          );
    // if(model.convertToDart) {
    //   model.convertedClass = FVBClass.create('${StringOperation.capitalize(model.name)}DataModel',vars: {
    //
    //   });
    // }
    return model;
  }
}

class RawBodyModel extends BodyModel {
  String code = '{}';

  RawBodyModel() : super('Raw');

  @override
  Map<String, dynamic> toJson() {
    return {'type': type, 'code': code};
  }

  @override
  fromJson(Map<String, dynamic> json) {
    code = json['code'];
  }

  String declareCode() {
    final String out = CodeOperations.trim(code) ?? 'null';
    return out.isNotEmpty ? code : '{}';
  }
}

abstract class BodyModel {
  final String type;

  BodyModel(this.type);

  Map<String, dynamic> toJson();

  fromJson(Map<String, dynamic> json);

  factory BodyModel.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'Raw') {
      return RawBodyModel()..fromJson(json);
    }
    throw Exception('Type ${json['type']} not found');
  }

  String declareCode() {
    if (type == 'Raw') {
      return (this as RawBodyModel).declareCode();
    }
    return '';
  }
}
