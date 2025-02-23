/// Example of Generated API Code.
import 'package:dio/dio.dart';

final Dio _dio = Dio();

class ApiResponseModel {
  final String? body;
  final int status;
  final String? error, message;
  final String? statusMessage;
  final Map<String, List<String>>? headers;
  final Map<String, dynamic>? extra;

  ApiResponseModel(
    this.body,
    this.status, {
    this.error,
    this.headers,
    this.message,
    this.statusMessage,
    this.extra,
  });
}

String baseURL = 'https://jsonplaceholder.typicode.com/';
String reqResURL = 'https://reqres.in/api/';
String salon = 'https://staging.edwardfox.com.au/salon/api/v1/operator/list';

class apis {
  static final todo = Todo.singleton();
  static final reqres = Reqres.singleton();
  static final add_user = AddUser.singleton();
  static final get_operators = GetOperators.singleton();
}

class Todo {
  static Todo? todo;
  Todo();
  factory Todo.singleton() {
    if (todo != null) {
      return todo!;
    }
    return todo = Todo();
  }

  Future<ApiResponseModel> fetch({int index = 5}) async {
    final String base = '${baseURL}todos/$index';
    final String method = 'GET';
    final Map<String, dynamic> header = {};
    final Map<String, dynamic> body = {};

    final queryParameters = <String, dynamic>{};
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
            method: method, headers: header, extra: {})
        .compose(_dio.options, '', queryParameters: queryParameters, data: body)
        .copyWith(baseUrl: base)));
    return ApiResponseModel(
      _result.data.toString(),
      _result.statusCode ?? -1,
      extra: _result.extra,
      headers: _result.headers.map,
      statusMessage: _result.statusMessage,
    );
  }
}

class Reqres {
  static Reqres? reqres;
  Reqres();
  factory Reqres.singleton() {
    if (reqres != null) {
      return reqres!;
    }
    return reqres = Reqres();
  }

  Future<ApiResponseModel> fetch({int page = 2}) async {
    final String base = '${reqResURL}users?page=$page';
    final String method = 'GET';
    final Map<String, dynamic> header = {};
    final Map<String, dynamic> body = {};

    final queryParameters = <String, dynamic>{};
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
            method: method, headers: header, extra: {})
        .compose(_dio.options, '', queryParameters: queryParameters, data: body)
        .copyWith(baseUrl: base)));
    return ApiResponseModel(
      _result.data.toString(),
      _result.statusCode ?? -1,
      extra: _result.extra,
      headers: _result.headers.map,
      statusMessage: _result.statusMessage,
    );
  }
}

class AddUser {
  static AddUser? add_user;
  AddUser();
  factory AddUser.singleton() {
    if (add_user != null) {
      return add_user!;
    }
    return add_user = AddUser();
  }

  Future<ApiResponseModel> fetch(
      {String name = 'test', String job = 'manager'}) async {
    final String base = '${reqResURL}users';
    final String method = 'POST';
    final Map<String, dynamic> header = {};
    final Map<String, dynamic> body = {'name': name, 'job': job};

    final queryParameters = <String, dynamic>{};
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
            method: method, headers: header, extra: {})
        .compose(_dio.options, '', queryParameters: queryParameters, data: body)
        .copyWith(baseUrl: base)));
    return ApiResponseModel(
      _result.data.toString(),
      _result.statusCode ?? -1,
      extra: _result.extra,
      headers: _result.headers.map,
      statusMessage: _result.statusMessage,
    );
  }
}

class GetOperators {
  static GetOperators? get_operators;
  GetOperators();
  factory GetOperators.singleton() {
    if (get_operators != null) {
      return get_operators!;
    }
    return get_operators = GetOperators();
  }

  Future<ApiResponseModel> fetch(
      {String Token = 'MGFjNGEyMjU2MDYxNDFlZjg3NDI3Nzk1YjY4YjdjMjM=',
      int company_id = 20136}) async {
    final String base = '$salon';
    final String method = 'POST';
    final Map<String, dynamic> header = {'authorization': 'Bearer $Token'};
    final Map<String, dynamic> body = {
      'filters': {'company_id': company_id}
    };

    final queryParameters = <String, dynamic>{};
    final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
            method: method, headers: header, extra: {})
        .compose(_dio.options, '', queryParameters: queryParameters, data: body)
        .copyWith(baseUrl: base)));
    return ApiResponseModel(
      _result.data.toString(),
      _result.statusCode ?? -1,
      extra: _result.extra,
      headers: _result.headers.map,
      statusMessage: _result.statusMessage,
    );
  }
}

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
