
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const TextToSpeechApp());
}

class TextToSpeechApp extends StatelessWidget {
  const TextToSpeechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Text to Speech',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5FC),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController textController =
      TextEditingController();

  final AudioPlayer audioPlayer = AudioPlayer();

  bool isGenerating = false;
  bool isPlaying = false;
  bool hasAudio = false;

  String statusMessage = 'Ready to generate speech';

  Future<void> generateSpeech() async {
    final text = textController.text.trim();

    if (text.isEmpty) {
      showMessage('Please enter some text first.');
      return;
    }

    setState(() {
      isGenerating = true;
      statusMessage = 'Generating your speech...';
      hasAudio = false;
    });

    try {
      await audioPlayer.stop();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/synthesize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'pitch_control': 1.0,
          'energy_control': 1.0,
          'duration_control': 1.0,
        }),
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        await audioPlayer.play(
          BytesSource(response.bodyBytes),
        );

        if (!mounted) return;

        setState(() {
          hasAudio = true;
          isPlaying = true;
          statusMessage = 'Speech generated successfully!';
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        statusMessage = 'Speech generation failed';
        hasAudio = false;
        isPlaying = false;
      });

      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  Future<void> pauseSpeech() async {
    await audioPlayer.pause();
    if (!mounted) return;

    setState(() {
      isPlaying = false;
      statusMessage = 'Speech paused';
    });
  }

  Future<void> resumeSpeech() async {
    await audioPlayer.resume();
    if (!mounted) return;

    setState(() {
      isPlaying = true;
      statusMessage = 'Playing speech...';
    });
  }

  Future<void> stopSpeech() async {
    await audioPlayer.stop();
    if (!mounted) return;

    setState(() {
      isPlaying = false;
      statusMessage = 'Speech stopped';
    });
  }

  void clearText() {
    textController.clear();

    setState(() {
      statusMessage = 'Ready to generate speech';
      hasAudio = false;
      isPlaying = false;
    });

    audioPlayer.stop();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text to Speech',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 15),

              const Icon(
                Icons.record_voice_over_rounded,
                size: 75,
                color: Color(0xFF6750A4),
              ),

              const SizedBox(height: 15),

              const Text(
                'Convert Text into Speech',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Transform your words into natural-sounding audio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 1,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Your Text',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: textController,
                        maxLines: 7,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Type or paste your text here...',
                          filled: true,
                          fillColor: const Color(0xFFF7F5FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${textController.text.length} characters',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: clearText,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed:
                      isGenerating ? null : generateSpeech,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.graphic_eq),
                  label: Text(
                    isGenerating
                        ? 'Generating Speech...'
                        : 'Generate & Play Speech',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Text(
                        'Audio Controls',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          IconButton.filled(
                            onPressed: hasAudio && isPlaying
                                ? pauseSpeech
                                : null,
                            icon: const Icon(Icons.pause),
                          ),
                          const SizedBox(width: 20),
                          IconButton.filled(
                            onPressed: hasAudio && !isPlaying
                                ? resumeSpeech
                                : null,
                            icon: const Icon(Icons.play_arrow),
                          ),
                          const SizedBox(width: 20),
                          IconButton.filled(
                            onPressed: hasAudio
                                ? stopSpeech
                                : null,
                            icon: const Icon(Icons.stop),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Powered by FastSpeech 2 & HiFi-GAN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
