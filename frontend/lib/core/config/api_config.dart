import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator maps host loopback to 10.0.2.2.
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}

