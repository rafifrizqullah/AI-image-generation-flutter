import 'package:dart_openai/dart_openai.dart';
import '../../env/env.dart';

/// Application configuration
class AppConfig {
  /// Initialize API configurations
  static void initialize() {
    // Configure OpenAI
    OpenAI.apiKey = Env.apiKey;
    OpenAI.showLogs = true;
  }
}

