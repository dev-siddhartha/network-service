import 'dart:typed_data';

import 'package:dio/dio.dart';

abstract class ApiManager {
  Dio? _dio;

  Dio? get dio;

  void initialize({
    required String baseURL,
    Duration connectTimeout,
    Duration receiveTimeout,
    String contentType,
    Map<String, dynamic> headers,
    String? pemCertificate,
    required bool isToEnableSSLCertificate,
    Uint8List? localCertificateBytes,
  });
}
