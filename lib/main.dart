import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_application_1/env/env.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

void main() {
  OpenAI.apiKey = Env.apiKey;
  OpenAI.showLogs = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AI Image Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _promptController = TextEditingController();
  String? _imageUrl;
  String? _caption;
  File? _selectedFile;
  bool _isLoading = false;

  void _handleFileSelected(File file) {
    print("Selected file: ${file.path}");
    // TODO: upload file, tampilkan preview, dsb
    setState(() {
      _selectedFile = file;
    });
  }

  void _handleOnSend(String prompt) async {
    if (_selectedFile != null) {
      final dataUrl = await encodeImageToDataUrl(_selectedFile!);
      // _analyzeImage(prompt, dataUrl);
      captionImage(prompt, _selectedFile!.path);
      // mockCaptionImage(prompt, _selectedFile!.path);
    } else {
      _generateImage(prompt);
    }
  }

  Future<void> _generateImage(String prompt) async {
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _imageUrl = null;
    });

    try {
      /// Real image generation
      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: prompt,
        model: 'dall-e-3',
        n: 1,
      );

      setState(() {
        _imageUrl = image.data.first.url;
        _isLoading = false;
      });

      /// Simulate image generation
      // await Future.delayed(const Duration(seconds: 2));

      // setState(() {
      //   _imageUrl = "https://imgur.com/HEAWRxy.png";
      //   _isLoading = false;
      // });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ OpenAI API error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OpenAI Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage(String prompt, String file) async {
    try {
      const url = 'https://api.openai.com/v1/responses';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.apiKey}',
      };

      final body = {
        "model": "gpt-4.1",
        "input": [
          {
            "role": "user",
            "content": [
              {"type": "input_text", "text": prompt},
              {"type": "input_image", "image_url": file},
            ],
          },
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(const JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('Error ${response.statusCode}: ${response.body}');
      }
    } on Exception catch (e) {
      // TODO
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> captionImage(String prompt, String imagePath) async {
    setState(() {
      _isLoading = true;
      _caption = null;
    });

    try {
      const String endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
      final String apiKey = Env.geminiApiKey;

      // 1️⃣ Baca file lokal dari path FilePicker
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ File tidak ditemukan: $imagePath');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Set the image URL to display the selected file
      setState(() {
        _imageUrl = 'file://$imagePath';
      });

      // 2️⃣ Baca isi file dan ubah ke Base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 3️⃣ Tentukan MIME type (opsional: deteksi dari ekstensi)
      String mimeType = 'image/jpeg';
      if (imagePath.endsWith('.png')) mimeType = 'image/png';
      if (imagePath.endsWith('.webp')) mimeType = 'image/webp';
      if (imagePath.endsWith('.jpg')) mimeType = 'image/jpeg';

      // 3️⃣ Buat payload
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

      // 4️⃣ Kirim ke Gemini REST API
      final response = await http
          .post(
            Uri.parse('$endpoint?key=$apiKey'),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      // 5️⃣ Tampilkan hasil
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'No caption';
        print('📝 Caption: $text');
        setState(() {
          _caption = text;
          _isLoading = false;
        });
      } else {
        print('Error ${response.statusCode}: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.statusCode} - ${response.body}'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Network error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> mockCaptionImage(String prompt, String imagePath) async {
    setState(() {
      _isLoading = true;
      _caption = null;
    });

    try {
      // 🧠 Ganti endpoint ke mock API (bisa juga ke server lokal kamu)
      const String endpoint = 'https://jsonplaceholder.typicode.com/posts';

      // 💡 Hanya kirim body sederhana dengan "text": prompt
      final body = jsonEncode({"text": """Berdasarkan gambar, deskripsi singkatnya adalah:

Seorang gadis dengan rambut hitam panjang sedang minum dari minuman dingin berbusa (kemungkinan kopi atau frappuccino) dengan sedotan hijau, tampak dalam gaya animasi dengan latar belakang biru solid.

Gadis itu mengenakan kemeja putih lengan panjang di balik rompi atau sweter abu-abu muda, dan sedang memegang cangkir transparan dengan tangan kanannya."""});

      // 🔹 Kirim HTTP POST
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // 🔹 Tampilkan hasil simulasi
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _caption = data['text'] ?? 'Mock response received';
          _isLoading = false;
          _imageUrl = 'file://$imagePath'; // masih tampilkan gambar lokal
        });

        print('✅ Mock response: $_caption');
      } else {
        print('⚠️ Error ${response.statusCode}: ${response.body}');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.statusCode}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Network error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> encodeImageToDataUrl(File file) async {
    // 1️⃣ Deteksi MIME type otomatis (misalnya image/png, image/jpeg)
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    // 2️⃣ Baca isi file sebagai bytes
    final bytes = await file.readAsBytes();

    // 3️⃣ Encode bytes ke base64
    final base64Data = base64Encode(bytes);

    // 4️⃣ Gabungkan ke dalam format data URL
    return 'data:$mimeType;base64,$base64Data';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : _imageUrl != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🖼️ Gambar
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                                  maxWidth: double.infinity,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _imageUrl!.startsWith('file://')
                                      ? Image.file(
                                          File(_imageUrl!.substring(7)),
                                          fit: BoxFit.contain,
                                        )
                                      : Image.network(
                                          _imageUrl!,
                                          fit: BoxFit.contain,
                                          loadingBuilder:
                                              (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 📝 Caption dari Gemini API
                              if (_caption != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _caption!,
                                  ),
                                ),
                            ],
                          )
                        : const Text('Pilih gambar atau masukkan prompt'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ChatInputField(
                onSend: _handleOnSend,
                onFileSelected: _handleFileSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatInputField extends StatefulWidget {
  final void Function(String text)? onSend;
  final void Function(File file)? onFileSelected;

  const ChatInputField({super.key, this.onSend, this.onFileSelected});

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _selectedImage;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _removeImage();
    _controller.clear();
    // Hide the on-screen keyboard using proper focus management
    _focusNode.unfocus();
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    print(_selectedImage);
  }

  Future<void> _handleAddFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (!mounted) return;

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      // Store the selected image for preview
      setState(() {
        _selectedImage = file;
      });
      print(_selectedImage);

      widget.onFileSelected?.call(file);

      // ✅ Optional: tampilkan snackbar agar user tahu file sudah dipilih
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Selected file: ${file.path.split('/').last}'),
      //     duration: const Duration(seconds: 2),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🖼️ Image preview
          if (_selectedImage != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _removeImage,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // 📝 Input text area
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 150, // batas tinggi maksimal
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                reverse: true,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "Describe your image here",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Buttons row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _handleAddFile,
              ),
              // IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: _handleSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
