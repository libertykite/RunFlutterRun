import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:run_flutter_run/core/refresh_token_utils.dart';
import '../../core/error.dart';
import '../../core/jwt_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

class RemoteApi {
  late String url;
  late Dio dio;
  late SharedPreferences prefs;

  RemoteApi(this.url) {
    dio = Dio();
    initCache();
  }

  Future<void> initCache() async {
    prefs = await SharedPreferences.getInstance();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final cacheKey = options.uri.toString();

        final cachedResponse = prefs.getString(cacheKey);

        if (options.method == 'GET' && cachedResponse != null) {
          final cacheTimestamp = prefs.getInt('$cacheKey:timestamp') ?? 0;

          final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
          final expirationDuration = const Duration(days: 1).inMilliseconds;

          if (currentTimestamp - cacheTimestamp <= expirationDuration) {
            handler.resolve(Response(
              data: jsonDecode(cachedResponse),
              statusCode: 200,
              requestOptions: options,
            ));
            return;
          } else {
            prefs.remove(cacheKey);
            prefs.remove('$cacheKey:timestamp');
          }
        }

        if (options.method == 'POST' ||
            options.method == 'PUT' ||
            options.method == 'DELETE') {
          prefs.remove('${url}all');
          prefs.remove('${url}all:timestamp');
        }

        handler.next(options);
      },
      onResponse: (response, handler) async {
        final cacheKey = response.requestOptions.uri.toString();
        final jsonResponse = jsonEncode(response.data);
        await prefs.setString(cacheKey, jsonResponse);

        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt('$cacheKey:timestamp', currentTimestamp);

        handler.next(response);
      },
      onError: (DioError error, ErrorInterceptorHandler handler) async {
        handler.next(error);
      },
    ));
  }

  Future<void> setJwt() async {
    final jwt = await JwtUtils.getJwt();
    if (jwt != null) {
      dio.options.headers['Authorization'] = 'Bearer $jwt';
    }
  }

  Future<Response?> handleUnauthorizedError(DioError error,
      Map<String, dynamic>? data, Map<String, dynamic>? queryParams) async {
    try {
      await JwtUtils.removeJwt();
      String jwt = await refreshToken();
      await JwtUtils.setJwt(jwt);
      try {
        var headers = error.requestOptions.headers;
        headers['Authorization'] = 'Bearer $jwt';
        return await dio.request(
          queryParameters: queryParams,
          data: data,
          error.requestOptions.path,
          options: Options(
            method: error.requestOptions.method,
            headers: headers,
            contentType: error.requestOptions.contentType,
            responseType: error.requestOptions.responseType,
          ),
        );
      } on DioError catch (_) {
        navigatorKey.currentState?.pushReplacementNamed('/login');
      }
    } on DioError {
      navigatorKey.currentState?.pushReplacementNamed('/login');
    }
    return null;
  }

  Future<String> refreshToken() async {
    try {
      String? refreshToken = await RefreshTokenUtils.getRefreshToken();
      const String apiUrl = 'https://runbackendrun.onrender.com/api/';
      final response = await dio
          .post('${apiUrl}user/refreshToken', data: {'token': refreshToken});

      if (response.statusCode == 200) {
        if (response.data.isNotEmpty) {
          return response.data['token'];
        }
      }
      throw const Failure(message: 'RefreshToken failed');
    } on DioError catch (err) {
      throw Failure(
          message: err.response?.statusMessage ?? 'Something went wrong!');
    } on SocketException {
      throw const Failure(message: 'Please check your connection.');
    }
  }
}

class ApiHelper {
  static const String apiUrl = 'https://runbackendrun.onrender.com/api/';

  static Future<Response?> makeRequest(
    String url,
    String method, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  }) async {
    final remoteApi = RemoteApi(url);
    await remoteApi.setJwt();

    try {
      Response? response;
      switch (method) {
        case 'GET':
          response = await remoteApi.dio.get(
            url,
            queryParameters: queryParams,
          );
          break;
        case 'POST':
          response = await remoteApi.dio.post(
            url,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'PUT':
          response = await remoteApi.dio.put(
            url,
            data: data,
            queryParameters: queryParams,
          );
          break;
        case 'DELETE':
          response = await remoteApi.dio.delete(
            url,
            queryParameters: queryParams,
          );
          break;
      }
      return response;
    } on DioError catch (error) {
      if (error.response?.statusCode == 401) {
        return remoteApi.handleUnauthorizedError(error, data, queryParams);
      }
      throw Failure(message: error.toString());
    }
  }
}
