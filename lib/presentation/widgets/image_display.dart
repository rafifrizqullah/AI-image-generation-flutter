import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/models/image_result.dart';

/// Widget to display generated images and captions
class ImageDisplay extends StatelessWidget {
  final ImageResult? result;
  final bool isLoading;

  const ImageDisplay({
    super.key,
    this.result,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result == null || !result!.hasImage) {
      return const Center(
        child: Text('Select an image or enter a prompt'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image
        _buildImage(context),
        
        const SizedBox(height: 12),

        // Caption (if available)
        if (result!.hasCaption) _buildCaption(context),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        maxWidth: double.infinity,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _getImageWidget(),
      ),
    );
  }

  Widget _getImageWidget() {
    if (result!.imageBytes != null) {
      return Image.memory(
        result!.imageBytes!,
        fit: BoxFit.contain,
      );
    } else if (result!.imageUrl != null) {
      if (result!.imageUrl!.startsWith('file://')) {
        return Image.file(
          File(result!.imageUrl!.substring(7)),
          fit: BoxFit.contain,
        );
      } else {
        return Image.network(
          result!.imageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildCaption(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(result!.caption!),
    );
  }
}

