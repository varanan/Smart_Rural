import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    const port = '3000'; // or '3000' if your backend runs on 3000

    if (kIsWeb) return 'http://localhost:$port/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port/api'; // Android emulator
    if (Platform.isIOS || Platform.isMacOS) return 'http://localhost:$port/api';
    if (Platform.isWindows || Platform.isLinux) return 'http://localhost:$port/api';
    return 'http://localhost:$port/api';
  }
}
