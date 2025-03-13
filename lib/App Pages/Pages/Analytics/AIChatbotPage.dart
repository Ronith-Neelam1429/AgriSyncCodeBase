import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class AIChatbotPage extends StatefulWidget {
  const AIChatbotPage({super.key});

  @override
  _AIChatbotPageState createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends State<AIChatbotPage> {
  final _questionController = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  String? _lastRecognizedWords;
  final String aiApiKey = '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';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _lastRecognizedWords = result.recognizedWords;
            _questionController.text = _lastRecognizedWords ?? '';
          });
        });
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _getAIResponse() async {
    setState(() {
      _isLoading = true;
    });
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() {
        _isLoading = false;
        _chatHistory.add({'user': question, 'bot': 'Please enter a question!'});
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    String userContext = '';
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        userContext =
            'User is a farmer with location: ${data['location'] ?? 'unknown'}, farm size: ${data['farmSize'] ?? 'unknown'}, and prefers crops: ${data['preferredCrops']?.join(', ') ?? 'unknown'}.';
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $aiApiKey',
          'HTTP-Referer': 'https://agrisync-app.com',
          'X-Title': 'AgriSync', 
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',
          'messages': [
            {'role': 'system', 'content': userContext},
            {'role': 'user', 'content': question},
          ],
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botResponse = data['choices'][0]['message']['content'].trim();
        setState(() {
          _chatHistory.add({'user': question, 'bot': botResponse});
          _isLoading = false;
          _questionController.clear();
        });
      } else {
        setState(() {
          _chatHistory.add({'user': question, 'bot': 'Error: Unable to get response.'});
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({'user': question, 'bot': 'Error: $e'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Farming Assistant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return Column(
                    crossAxisAlignment: chat['user']!.isNotEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      if (chat['user']!.isNotEmpty)
                        Text('You: ${chat['user']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (chat['bot']!.isNotEmpty)
                        Text('Bot: ${chat['bot']}', style: const TextStyle(color: Colors.green)),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(hintText: 'Ask a farming question...'),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: _startListening,
                  color: _isListening ? Colors.red : Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _getAIResponse,
                ),
              ],
            ),
            if (_isLoading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _speech.stop();
    super.dispose();
  }
}