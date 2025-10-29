import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/ai_provider.dart';
import '../providers/image_generation_provider.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/image_display.dart';

/// Home screen for AI image generation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Consumer<ImageGenerationProvider>(
                    builder: (context, provider, child) {
                      return ImageDisplay(
                        result: provider.currentResult,
                        isLoading: provider.isLoading,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildChatInput(context),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('AI Image Generator'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Consumer<ImageGenerationProvider>(
            builder: (context, provider, child) {
              return DropdownButton<AIProvider>(
                value: provider.selectedProvider,
                onChanged: (AIProvider? newValue) {
                  if (newValue != null) {
                    provider.setProvider(newValue);
                  }
                },
                items: AIProvider.values
                    .map<DropdownMenuItem<AIProvider>>((AIProvider provider) {
                  return DropdownMenuItem<AIProvider>(
                    value: provider,
                    child: Text(provider.displayName),
                  );
                }).toList(),
                underline: Container(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput(BuildContext context) {
    final provider = context.read<ImageGenerationProvider>();
    
    return ChatInputField(
      onSend: (text) {
        provider.handleSend(text);
        
        // Show error message if there's an error
        if (provider.currentResult?.hasError ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.currentResult!.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onFileSelected: (file) {
        provider.setSelectedFile(file);
      },
    );
  }
}

