import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static final Dio _dio = Dio();
  static String? companyToken;

  static Dio getInstance(SharedPreferences prefs) {
    _initializeInterceptors();
    return _dio;
  }

  static _initializeInterceptors() {
    _dio.interceptors
        .add(QueuedInterceptorsWrapper(onRequest: (options, handler) {
      return handler.next(options);
    }, onResponse: (response, handler) async {
      return handler.next(response);
    }, onError: (DioException e, handler) async {
      return handler.next(e);
    }));
    if (kDebugMode) {
      _dio.interceptors.add(
          LogInterceptor(responseBody: true, request: true, requestBody: true));
    }
  }
}
