import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/env/env.dart';

/// Service class for Google Gemini API operations
class GeminiService {
  static const String _imageGenerationEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent';
  static const String _visionEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final String _apiKey = Env.geminiApiKey;

  /// Generate an image from a text prompt
  Future<Uint8List?> generateImage(String prompt) async {
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse('$_imageGenerationEndpoint?key=$_apiKey'),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final parts = json['candidates']?[0]?['content']?['parts'] as List?;
        
        if (parts != null) {
          for (final part in parts) {
            if (part['text'] != null) {
              print('📝 Text: ${part['text']}');
            } else if (part['inlineData'] != null) {
              final dataString = part['inlineData']?['data'];
              if (dataString != null) {
                return base64Decode(dataString);
              } else {
                print('⚠️ No inlineData.data field in response');
              }
            }
          }
        } else {
          print('⚠️ No parts in response');
        }
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Gemini image generation error: ${e.toString()}');
      rethrow;
    }
    return null;
  }

  /// Generate a caption for an image file
  Future<String?> generateCaption(String prompt, String imagePath) async {
    try {
      // Read the image file
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ File not found: $imagePath');
        return null;
      }

      // Convert to base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine MIME type
      String mimeType = _getMimeType(imagePath);

      // Create payload
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inline_data": {"mime_type": mimeType, "data": base64Image},
              },
              {"text": prompt},
            ],
          },
        ],
      });

      // Send request to Gemini
      final response = await http.post(
        Uri.parse('$_visionEndpoint?key=$_apiKey'),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
                'No caption';
        print('📝 Caption: $text');
        return text;
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Gemini caption error: ${e.toString()}');
      rethrow;
    }
  }

  String _getMimeType(String imagePath) {
    if (imagePath.endsWith('.png')) return 'image/png';
    if (imagePath.endsWith('.webp')) return 'image/webp';
    if (imagePath.endsWith('.jpg') || imagePath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg'; // default
  }
}

