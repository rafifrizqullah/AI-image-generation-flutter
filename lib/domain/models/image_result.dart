import 'dart:typed_data';

/// Result model for image generation/captioning
class ImageResult {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? caption;
  final String? errorMessage;

  ImageResult({
    this.imageUrl,
    this.imageBytes,
    this.caption,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
  bool get hasImage => imageUrl != null || imageBytes != null;
  bool get hasCaption => caption != null;

  ImageResult copyWith({
    String? imageUrl,
    Uint8List? imageBytes,
    String? caption,
    String? errorMessage,
  }) {
    return ImageResult(
      imageUrl: imageUrl ?? this.imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      caption: caption ?? this.caption,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

