import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/ai_provider.dart';
import '../../domain/models/image_result.dart';
import '../../domain/repositories/image_generation_repository.dart';

/// ViewModel/Provider for image generation functionality
class ImageGenerationProvider extends ChangeNotifier {
  final ImageGenerationRepository _repository;

  ImageGenerationProvider({
    required ImageGenerationRepository repository,
  }) : _repository = repository;

  // State
  bool _isLoading = false;
  ImageResult? _currentResult;
  AIProvider _selectedProvider = AIProvider.openai;
  File? _selectedFile;

  // Getters
  bool get isLoading => _isLoading;
  ImageResult? get currentResult => _currentResult;
  AIProvider get selectedProvider => _selectedProvider;
  File? get selectedFile => _selectedFile;

  /// Change the selected AI provider
  void setProvider(AIProvider provider) {
    _selectedProvider = provider;
    notifyListeners();
  }

  /// Set the selected file for captioning
  void setSelectedFile(File? file) {
    _selectedFile = file;
    notifyListeners();
  }

  /// Generate an image from a text prompt
  Future<void> generateImage(String prompt) async {
    if (prompt.isEmpty) return;

    _isLoading = true;
    _currentResult = null;
    notifyListeners();

    try {
      String? imageUrl;
      Uint8List? imageBytes;

      switch (_selectedProvider) {
        case AIProvider.openai:
          imageUrl = await _repository.generateImageUrl(
            prompt,
            _selectedProvider,
          );
          break;
        case AIProvider.gemini:
          imageBytes = await _repository.generateImageBytes(
            prompt,
            _selectedProvider,
          );
          break;
      }

      if (kDebugMode) {
        debugPrint('Image url: $imageUrl');
        debugPrint('Image bytes: $imageBytes');
      }

      if (imageUrl != null || imageBytes != null) {
        _currentResult = ImageResult(
          imageUrl: imageUrl,
          imageBytes: imageBytes,
        );
      } else {
        _currentResult = ImageResult(
          errorMessage: 'Failed to generate image with ${_selectedProvider.displayName}',
        );
      }
    } catch (e) {
      print('❌ ${_selectedProvider.displayName} API error: ${e.toString()}');
      _currentResult = ImageResult(
        errorMessage: '${_selectedProvider.displayName} Error: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a caption for the selected image
  Future<void> generateCaption(String prompt, String imagePath) async {
    _isLoading = true;
    _currentResult = null;
    notifyListeners();

    try {
      final caption = await _repository.generateImageCaption(prompt, imagePath);

      if (caption != null) {
        _currentResult = ImageResult(
          imageUrl: 'file://$imagePath',
          caption: caption,
        );
      } else {
        _currentResult = ImageResult(
          errorMessage: 'Failed to generate caption',
        );
      }
    } catch (e) {
      print('❌ Caption error: ${e.toString()}');
      _currentResult = ImageResult(
        imageUrl: 'file://$imagePath',
        errorMessage: 'Network Error: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle send action - either generate image or caption based on context
  Future<void> handleSend(String prompt) async {
    if (_selectedFile != null) {
      await generateCaption(prompt, _selectedFile!.path);
    } else {
      await generateImage(prompt);
    }
  }

  /// Clear current results
  void clearResults() {
    _currentResult = null;
    _selectedFile = null;
    notifyListeners();
  }
}

