import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'api_manager_impl.dart';
import 'api_request_impl.dart';
import 'interface/api_manager.dart';
import 'interface/api_request.dart';

class NetworkService {
  NetworkService._();

  static final NetworkService _instance = NetworkService._();

  factory NetworkService() => _instance;

  static late ApiRequest _apiRequest;
  static late ApiManager _apiManager;

  static ApiRequest get apiRequest => _apiRequest;

  static ApiManager get apiManager => _apiManager;

  static void configureNetworkService({
    String baseURL = "",
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 25),
    String contentType = Headers.jsonContentType,
    Map<String, dynamic> headers = const {"Accept": "application/json"},
    String? pemCertificate,
    Uint8List? localCertificateBytes,
  }) async {
    _apiManager = ApiManagerImpl();
    _apiRequest = ApiRequestImpl();
    NetworkService._apiManager.initialize(
      baseURL: baseURL,
      headers: headers,
      connectTimeout: connectTimeout,
      contentType: contentType,
      isToEnableSSLCertificate:
          (pemCertificate != null) || (localCertificateBytes != null),
      localCertificateBytes: localCertificateBytes,
      pemCertificate: pemCertificate,
      receiveTimeout: receiveTimeout,
    );
  }
}
