// lib/services/api_config.dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  // For Android emulator, 10.0.2.2 maps to host machine's localhost
  // For web/desktop, use localhost directly
  static String get baseUrl {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:3000/api';
    }
    // Physical Android device — use host machine's WiFi IP
    return 'http://172.20.10.2:3000/api';
  }

  // Timeout duration for API calls
  static const Duration timeout = Duration(seconds: 15);
}
