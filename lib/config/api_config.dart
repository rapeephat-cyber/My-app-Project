import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost/timeguard_api/';
    }
    return 'http://10.0.2.2/timeguard_api/';
  }

  static const timeout = Duration(seconds: 60);
}