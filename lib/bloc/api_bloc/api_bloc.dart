import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:fvb_processor/compiler/code_processor.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/api/api_model.dart';
import '../../injector.dart';
import '../../ui/fvb_code_editor.dart';
import '../error/error_bloc.dart';

part 'api_event.dart';
part 'api_state.dart';

class FVBApiBloc extends Bloc<ApiEvent, FVBApiState> {
  late final Processor processor;
  late final ApiViewModel apiViewModel;
  final _bloc = sl<EventLogBloc>();
  final Dio _dio = Dio();

  FVBApiBloc() : super(ApiInitial()) {
    _dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        logPrint: (data) {
          _bloc.add(ConsoleUpdatedEvent(
              ConsoleMessage(data.toString(), ConsoleMessageType.event)));
        }));
    apiViewModel = ApiViewModel();
    processor = Processor(
        scopeName: 'api_test',
        consoleCallback: (name, {List<dynamic>? arguments}) {
          return null;
        },
        onError: (error, line) {
          print('ERROR $error');
        });
    on<ApiEvent>((event, emit) {});
    on<ApiProcessingErrorEvent>(_onProcessingErrorEvent);
    on<ApiTestEvent>(_apiTestEvent);
    on<ApiFireEvent>((event, emit) async {
      // emit(ApiLoadingState());
    });
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

  Future<ApiResponseModel?> callApi(
      Processor processor, ApiDataModel model, List<dynamic> arguments) async {
    final processed = model.process(arguments: arguments);
    if (processed.isLeft) {
      final response = await _performApiCall(processed.left);
      return response;
    }
    for (final error in processed.right) {
      processor.enableError(error);
    }
    return null;
  }

  Future<ApiResponseModel> _performApiCall(ApiProcessedModel model) async {
    try {
      /// Raw-Body + Post
      final queryParameters = <String, dynamic>{};
      // _data.addAll(param);
      final _result = await _dio.fetch<String>(_setStreamType<String>(
          Options(method: model.method, headers: model.header, extra: {})
              .compose(_dio.options, '',
                  queryParameters: queryParameters, data: model.body)
              .copyWith(baseUrl: model.baseURL)));
      return ApiResponseModel(
        _result.data.toString(),
        _result.statusCode ?? -1,
        extra: _result.extra,
        headers: _result.headers.map,
        statusMessage: _result.statusMessage,
      );

      /// GET

      // const _extra = <String, dynamic>{};
      // final queryParameters = <String, dynamic>{};
      // final _headers = <String, dynamic>{};
      // final _data = <String, dynamic>{};
      // final _result = await _dio.fetch<Map<String, dynamic>>(
      //     _setStreamType<MatchDetailsResponse>(
      //         Options(method: 'GET', headers: _headers, extra: _extra)
      //             .compose(_dio.options, 'match-detail/${id}',
      //             queryParameters: queryParameters, data: _data)
      //             .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
      // final value = MatchDetailsResponse.fromJson(_result.data!);

      /// Multipart + Post

      // const _extra = <String, dynamic>{};
      // final queryParameters = <String, dynamic>{};
      // final _headers = <String, dynamic>{};
      // final _data = FormData();
      // _data.fields.add(MapEntry('username', username));
      // _data.fields.add(MapEntry('password', password));
      // final _result = await _dio.fetch<String>(_setStreamType<String>(Options(
      //     method: 'POST',
      //     headers: _headers,
      //     extra: _extra,
      //     contentType: 'multipart/form-data')
      //     .compose(_dio.options, 'login/user_login',
      //     queryParameters: queryParameters, data: _data)
      //     .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    } on DioException catch (e) {
      return ApiResponseModel(e.response?.data, e.response?.statusCode ?? -1,
          statusMessage: e.response?.statusMessage,
          extra: e.response?.extra,
          message: e.message,
          error: e.error.toString());
    }
  }

  void _apiTestEvent(ApiTestEvent event, Emitter<FVBApiState> emit) async {
    emit(ApiLoadingState(event.apiViewModel));
    emit(ApiResponseState(
        await _performApiCall(event.apiViewModel), event.apiViewModel));
  }

  void _onProcessingErrorEvent(
      ApiProcessingErrorEvent event, Emitter<FVBApiState> emit) {
    emit(ApiProcessingErrorState(event.errorList));
  }
}

class ApiViewModel {
  String method = 'GET';
  String url = '';
  String urlValue = '';
  String params = '';
  dynamic paramValue;
  String body = '';
  dynamic bodyValue;
  String header = '';
  dynamic headerValue;

  ApiViewModel() {
    final pref = sl<SharedPreferences>();
    method = pref.getString('method') ?? 'GET';
    url = pref.getString('url') ?? '';
    params = pref.getString('params') ?? '';
    body = pref.getString('body') ?? '';
    header = pref.getString('header') ?? '';
  }

  Future<void> save() async {
    final pref = sl<SharedPreferences>();
    await pref.setString('method', method);
    await pref.setString('url', url);
    await pref.setString('params', params);
    await pref.setString('body', body);
    await pref.setString('header', header);
  }
}

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
