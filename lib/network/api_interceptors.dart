import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant/http_status_code.dart';
import 'constant/shared_prefs_key.dart';

class ApiInterceptor extends Interceptor {
  final Dio dioInstance;

  ApiInterceptor({required this.dioInstance});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String key = _getKey(
      path: options.path,
      queryParameters: options.queryParameters,
      data: options.data,
    );

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool isToRefresh =
        sharedPreferences.getBool(SharedPrefsKey.isToRefreshKey) ?? true;
    String? cachedData = sharedPreferences.getString(key);

    if (cachedData != null && !isToRefresh) {
      Map<String, dynamic> responseData = jsonDecode(cachedData);
      // log("decoded responseData : $responseData");

      DateTime expiryDate =
          DateTime.parse(responseData[SharedPrefsKey.expiryDateMapKey]);
      bool isExpired = DateTime.now().isAfter(expiryDate);
      if (!isExpired) {
        // If cached data exists, use it and complete the request.
        Response cachedResponse = Response(
          requestOptions: options,
          data: jsonDecode(responseData[SharedPrefsKey.dataMapKey]),
          statusCode: HttpStatusCode.successStatusCode,
        );
        return handler.resolve(cachedResponse);
      }
    }

    // Continue with the original request.
    options.headers.putIfAbsent('user-agent', () => "dart:io");
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    Response myResponse = response;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool isToCache =
        sharedPreferences.getBool(SharedPrefsKey.isToCacheKey) ?? false;
    int expiryDurationInDays =
        sharedPreferences.getInt(SharedPrefsKey.expiryDurationInDaysKey) ?? 0;
    log("cache: $isToCache, expiry duration in days: $expiryDurationInDays");

    String key = _getKey(
      path: myResponse.requestOptions.path,
      queryParameters: myResponse.requestOptions.queryParameters,
      data: myResponse.requestOptions.data,
    );

    if (isToCache) {
      if (myResponse.statusCode == HttpStatusCode.createStatusCode ||
          myResponse.statusCode == HttpStatusCode.successStatusCode) {
        Map<String, dynamic> responseData = {
          SharedPrefsKey.expiryDateMapKey: DateTime.now()
              .add(Duration(days: expiryDurationInDays))
              .toString(),
          SharedPrefsKey.dataMapKey: response.toString(),
        };
        await sharedPreferences.setString(key, jsonEncode(responseData));
      }
    }
    super.onResponse(myResponse, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    DioException myErr = err;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String key = _getKey(
      path: myErr.requestOptions.path,
      queryParameters: myErr.requestOptions.queryParameters,
      data: myErr.requestOptions.data,
    );

    if (myErr.type == DioExceptionType.connectionTimeout ||
        myErr.type == DioExceptionType.receiveTimeout ||
        myErr.type == DioExceptionType.connectionError ||
        err.error is SocketException) {
      String? data = sharedPreferences.getString(key);
      if (data != null) {
        try {
          var myResponse = jsonDecode(data);
          myErr = myErr.copyWith(
            response: Response(
              requestOptions: myErr.requestOptions,
              data: myResponse,
              extra: myErr.requestOptions.extra,
              statusCode: 200,
            ),
          );
        } catch (e) {
          return handler.next(myErr);
        }
      }
    }

    return handler.next(myErr);
  }

  String _getKey(
      {required String path,
      required Map<String, dynamic> queryParameters,
      required dynamic data}) {
    String key = path;
    if (queryParameters.isNotEmpty) {
      key = key + jsonEncode(queryParameters);
    }

    if (data != null) {
      key = key + jsonEncode(data);
    }
    return key;
  }
}
