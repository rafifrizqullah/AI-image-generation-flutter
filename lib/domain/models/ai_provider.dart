/// Enum representing different AI image generation providers
enum AIProvider {
  openai,
  gemini,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI DALL-E 3';
      case AIProvider.gemini:
        return 'Google Gemini';
    }
  }
}

