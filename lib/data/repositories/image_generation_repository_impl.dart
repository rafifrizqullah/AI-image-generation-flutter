import 'dart:typed_data';
import '../../domain/models/ai_provider.dart';
import '../../domain/repositories/image_generation_repository.dart';
import '../services/openai_service.dart';
import '../services/gemini_service.dart';

/// Implementation of ImageGenerationRepository
class ImageGenerationRepositoryImpl implements ImageGenerationRepository {
  final OpenAIService _openAIService;
  final GeminiService _geminiService;

  ImageGenerationRepositoryImpl({
    required OpenAIService openAIService,
    required GeminiService geminiService,
  })  : _openAIService = openAIService,
        _geminiService = geminiService;

  @override
  Future<String?> generateImageUrl(String prompt, AIProvider provider) async {
    try {
      switch (provider) {
        case AIProvider.openai:
          return await _openAIService.generateImage(prompt);
        case AIProvider.gemini:
          // Gemini returns bytes, not URL
          return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Uint8List?> generateImageBytes(
      String prompt, AIProvider provider) async {
    try {
      switch (provider) {
        case AIProvider.openai:
          // OpenAI returns URL, not bytes
          return null;
        case AIProvider.gemini:
          return await _geminiService.generateImage(prompt);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> generateImageCaption(String prompt, String imagePath) async {
    try {
      return await _geminiService.generateCaption(prompt, imagePath);
    } catch (e) {
      rethrow;
    }
  }
}

