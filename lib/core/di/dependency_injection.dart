import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../data/repositories/image_generation_repository_impl.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/openai_service.dart';
import '../../domain/repositories/image_generation_repository.dart';
import '../../presentation/providers/image_generation_provider.dart';

/// Dependency injection setup using Provider
class DependencyInjection {
  /// Get list of providers for the app
  static List<SingleChildWidget> getProviders() {
    return [
      // Services
      Provider<OpenAIService>(
        create: (_) => OpenAIService(),
      ),
      Provider<GeminiService>(
        create: (_) => GeminiService(),
      ),

      // Repositories
      ProxyProvider2<OpenAIService, GeminiService, ImageGenerationRepository>(
        update: (_, openAIService, geminiService, __) =>
            ImageGenerationRepositoryImpl(
          openAIService: openAIService,
          geminiService: geminiService,
        ),
      ),

      // Providers/ViewModels
      ChangeNotifierProxyProvider<ImageGenerationRepository,
          ImageGenerationProvider>(
        create: (context) => ImageGenerationProvider(
          repository: context.read<ImageGenerationRepository>(),
        ),
        update: (_, repository, previous) =>
            previous ?? ImageGenerationProvider(repository: repository),
      ),
    ];
  }
}

