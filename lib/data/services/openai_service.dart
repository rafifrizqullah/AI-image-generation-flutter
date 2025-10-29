import 'package:dart_openai/dart_openai.dart';

/// Service class for OpenAI API operations
class OpenAIService {
  /// Generate an image URL using DALL-E 3
  Future<String?> generateImage(String prompt) async {
    try {
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        model: 'dall-e-3',
        n: 1,
      );
      return image.data.first.url;
    } catch (e) {
      rethrow;
    }
  }
}

