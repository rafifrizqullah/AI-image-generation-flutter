import 'dart:typed_data';
import '../models/ai_provider.dart';

/// Repository interface for image generation operations
abstract class ImageGenerationRepository {
  /// Generate an image from a text prompt using the specified AI provider
  Future<String?> generateImageUrl(String prompt, AIProvider provider);
  
  /// Generate an image as bytes from a text prompt using the specified AI provider
  Future<Uint8List?> generateImageBytes(String prompt, AIProvider provider);
  
  /// Generate a caption/description for an uploaded image
  Future<String?> generateImageCaption(String prompt, String imagePath);
}

