import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'api_interceptors.dart';
import 'interface/api_manager.dart';

class ApiManagerImpl implements ApiManager {
  @override
  Dio? _dio;

  @override
  Dio? get dio => _dio;

  @override
  void initialize({
    required String baseURL,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 25),
    String contentType = Headers.jsonContentType,
    Map<String, dynamic> headers = const {"Accept": "application/json"},
    String? pemCertificate,
    required bool isToEnableSSLCertificate,
    Uint8List? localCertificateBytes,
  }) {
    BaseOptions options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      contentType: contentType,
      headers: headers,
    );

    _dio = Dio(options);
    _dio!.interceptors.add(ApiInterceptor(dioInstance: _dio!));

    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient httpClient = HttpClient();

      bool hasPemCertificate =
          pemCertificate != null || localCertificateBytes != null;
      if (isToEnableSSLCertificate && !hasPemCertificate) {
        log("::: SSL Certificate Has Enabled But No PEM Certificate Was Added :::");
      }
      assert(
          !(isToEnableSSLCertificate &&
              (pemCertificate == null && localCertificateBytes == null)),
          "SSL certificate is enabled, but no PEM certificate was provided.");

      if (isToEnableSSLCertificate && hasPemCertificate) {
        String? certificate = pemCertificate;
        Uint8List? certificateBytes = localCertificateBytes;

        if (certificate != null) {
          if (localCertificateBytes == null) {
            certificateBytes = Uint8List.fromList(utf8.encode(certificate));
          }
          SecurityContext sc = SecurityContext();
          sc.setTrustedCertificatesBytes(
            certificateBytes!,
          );
          httpClient = HttpClient(context: sc);
          // httpClient.badCertificateCallback =
          //     (X509Certificate cert, String host, int port) {
          //   if (host == "api.ambition.guru") {
          //     return true;
          //   }
          //   return false;
          // };
          return httpClient;
        } else {
          httpClient.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
          return httpClient;
        }
      } else {
        httpClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return httpClient;
      }
    };
  }
}
