import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:network_service/network/constant/enums.dart';
import 'package:network_service/network/newtork_service.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'constant/shared_prefs_key.dart';
import 'failure_state.dart';
import 'interface/api_request.dart';

class ApiRequestImpl implements ApiRequest {
  @override
  Future<Either<dynamic, FailureState>> getResponse({
    required String endPoint,
    required ApiMethods apiMethods,
    Map<String, dynamic>? queryParams,
    body,
    Options? options,
    bool isToCache = true,
    bool isToRefresh = false,
    int expiryDurationInDays = 3,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await Future.wait([
      sharedPreferences.setBool(SharedPrefsKey.isToCacheKey, isToCache),
      sharedPreferences.setBool(SharedPrefsKey.isToRefreshKey, isToRefresh),
      sharedPreferences.setInt(
          SharedPrefsKey.expiryDurationInDaysKey, expiryDurationInDays),
    ]);
    var apiManager = NetworkService.apiManager;
    String url = endPoint;

    String cancelURL = endPoint;
    if (queryParams != null) {
      cancelURL = cancelURL + jsonEncode(queryParams);
    }
    try {
      if (body != null) {
        cancelURL = cancelURL + jsonEncode(body);
      }
    } catch (e) {
      // do nothing
    }

    var cancelToken = CancelToken();
    cancelTokens.addAll({cancelURL: cancelToken});

    switch (apiMethods) {
      case ApiMethods.post:
        return decodeHttpRequestResponse(
          apiManager.dio!.post(
            url,
            cancelToken: cancelToken,
            data: body,
            options: options,
            queryParameters: queryParams,
          ),
        );
      case ApiMethods.delete:
        return decodeHttpRequestResponse(
          apiManager.dio!.delete(
            url,
            data: body,
            options: options,
            queryParameters: queryParams,
          ),
        );
      case ApiMethods.get:
      default:
        return decodeHttpRequestResponse(
          apiManager.dio!.get(
            url,
            options: options,
            queryParameters: queryParams,
          ),
        );
    }
  }

  @override
  Future<Either<dynamic, FailureState>> decodeHttpRequestResponse(
    Future<dynamic> apiCall, {
    String message = "",
  }) async {
    try {
      Response? response = await apiCall;

      List<int> successStatusCode = [200, 201];
      if (successStatusCode.contains(response?.statusCode)) {
        return Left({'data': response?.data, 'message': message});
      } else if (response?.statusCode == 500) {
        return Right(FailureState(message: 'Something went wrong'));
      } else if (response?.statusCode == 401) {
        return Right(FailureState(message: 'Something went wrong'));
      } else if (response?.statusCode == 400) {
        return Right(FailureState.fromJson(response!.data));
      } else if (response?.statusCode == 422) {
        return Right(FailureState.fromJson(response!.data));
      } else if (response?.data == null) {
        return Right(response?.data);
      } else {
        return Right(FailureState(message: 'Something went wrong'));
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        if (e.response?.statusCode == 200) {
          return Left(e.response!.data);
        }
      }
      return Right(FailureState(message: 'Something went wrong'));
    } catch (e) {
      return Right(FailureState(message: 'Something went wrong'));
    }
  }

  @override
  Map<String, CancelToken> cancelTokens = {};

  @override
  void cancelRequest(String url) {
    if (cancelTokens.containsKey(url)) {
      final token = cancelTokens[url];
      if (token != null) {
        token.cancel("Cancelled $url");
      }
      cancelTokens.removeWhere((key, value) => key == url);
    }
  }

  @override
  Future<Either<dynamic, FailureState>> uploadAnyMultipleFile({
    required String endPoint,
    required List<File> files,
    required FormData formData,
    required String key,
    required UploadType uploadType,
  }) async {
    FormData formData0 = formData;
    await Future.forEach(files, (file) async {
      String fileName = file.path.split('/').last;
      MultipartFile multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType(
          (uploadType != UploadType.audio || uploadType != UploadType.pdf)
              ? "image"
              : uploadType.toString(),
          path.extension(path.basename(file.path)).replaceAll('.', ''),
        ),
      );
      formData0.files.add(MapEntry(key, multipartFile));
    });
    return getResponse(
      apiMethods: ApiMethods.post,
      endPoint: endPoint,
      body: formData0,
      isToCache: false,
    );
  }

  @override
  Future<Either<dynamic, FailureState>> uploadAnySingleFile({
    required String endPoint,
    required File file,
    required FormData formData,
    required String key,
    required UploadType uploadType,
  }) async {
    FormData formData0 = formData;
    String fileName = file.path.split('/').last;
    MultipartFile multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: fileName,
      contentType: MediaType(
        (uploadType != UploadType.audio || uploadType != UploadType.pdf)
            ? "image"
            : uploadType.toString(),
        path.extension(path.basename(file.path)).replaceAll('.', ''),
      ),
    );
    formData0.files.add(MapEntry(key, multipartFile));
    return getResponse(
      apiMethods: ApiMethods.post,
      endPoint: endPoint,
      body: formData0,
      isToCache: false,
    );
  }
}
