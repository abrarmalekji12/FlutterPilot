
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:get/get.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/compiler/code_processor.dart';
import 'package:http/http.dart' as http;

import '../../injector.dart';

part 'api_event.dart';

part 'api_state.dart';

class ApiBloc extends Bloc<ApiEvent, ApiState> {
  late final CodeProcessor processor;
  late final ApiViewModel apiViewModel;

  ApiBloc() : super(ApiInitial()) {
    apiViewModel= ApiViewModel();
    processor = CodeProcessor(
        scopeName: 'api_test',
        consoleCallback: (name, {List<dynamic>? arguments}) {

        },
        onError: (error, line) {
          print('ERROR $error');
        });
    on<ApiEvent>((event, emit) {});
    on<ApiFireEvent>((event,emit) async {
      emit(ApiLoadingState());
      final model=event.apiViewModel;
      try {
        if (model.method == 'GET') {
          final response = await http.get(
              Uri.parse(model.urlValue), headers: model.headerValue);
          emit(ApiResponseState(ApiResponseModel(
              response.body, response.statusCode, headers: response.headers)));
        }
        else if(model.method == 'POST'){
          final response = await http.post(
              Uri.parse(model.urlValue), headers: model.headerValue,body: model.bodyValue.map);
          emit(ApiResponseState(ApiResponseModel(
              response.body, response.statusCode, headers: response.headers)));

        }
      }
      on SocketException catch(e){
        emit(ApiResponseState(ApiResponseModel(e.message,400)));
      }
      on HttpException catch(e){
        emit(ApiResponseState(ApiResponseModel(e.message,400)));
      }
      on Exception catch(e){
        emit(ApiResponseState(ApiResponseModel(e.toString(),400)));
      }
      catch(e){
        emit(ApiResponseState(ApiResponseModel(e.toString(),400)));
       }
    });
  }
}

class ApiViewModel {
  String method = 'GET';
  String url = '';
  String urlValue='';
  String params = '';
  dynamic paramValue;
  String body = '';
  dynamic bodyValue;
  String header = '';
  dynamic headerValue;
  ApiViewModel(){
    final pref=get<SharedPreferences>();
    method=pref.getString('method')??'GET';
    url=pref.getString('url')??'';
    params=pref.getString('params')??'';
    body=pref.getString('body')??'';
    header=pref.getString('header')??'';
  }

  Future<void> save() async {
    final pref=get<SharedPreferences>();
    await pref.setString('method',method);
    await pref.setString('url',url);
    await pref.setString('params',params);
    await pref.setString('body',body);
    await pref.setString('header',header);

  }
}
class ApiResponseModel{
  final String? body;
  final int status;
  final String? error;
  final Map<String,String>? headers;

  ApiResponseModel(this.body, this.status, {this.error,this.headers});
}
