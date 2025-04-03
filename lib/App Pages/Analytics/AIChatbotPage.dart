import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:agrisync/App Pages/Weather/LocationService.dart';

class AIChatbotPage extends StatefulWidget {
  const AIChatbotPage({super.key});

  @override
  _AIChatbotPageState createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends State<AIChatbotPage> {
  final _questionController = TextEditingController(); // For user input
  final List<Map<String, String>> _chatHistory = []; // Stores chat messages
  final ScrollController _scrollController = ScrollController(); // Controls chat scrolling
  bool _isLoading = false; // Shows if AI is thinking
  bool _isListening = false; // Tracks mic status
  late stt.SpeechToText _speech; // Speech-to-text setup
  final String aiApiKey =
      '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'; // AI API key
  String _userContext = ""; // User’s farm details
  String _userFirstName = "Farmer"; // Default name if none found
  String _weatherInfo = ""; // Current weather info
  final String weatherApiKey = 'eeaca43a04ac307588b75ac98f9871d7'; // Weather API key

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _requestMicrophonePermission(); // Ask for mic access right away
    _loadUserAndWeatherInfo(); // Load user and weather data when page starts
  }

  // Grabs user info and weather to personalize the chat
  Future<void> _loadUserAndWeatherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _userFirstName = data['firstName'] ?? "Farmer";
          _userContext =
              "Location: ${data['location'] ?? 'unknown'}, Farm Size: ${data['farmSize'] ?? 'unknown'}, Preferred Crops: ${(data['preferredCrops'] as List?)?.join(', ') ?? 'unknown'}.";
        }
      } catch (e) {
        debugPrint("Error loading user info: $e");
      }
      try {
        final location = await LocationService.getCurrentLocation();
        if (location != null) {
          final lat = location['latitude'];
          final lon = location['longitude'];
          final url =
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric';
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final weatherData = json.decode(response.body);
            final temp = weatherData['main']['temp'];
            final condition = weatherData['weather'][0]['main'];
            _weatherInfo = "Weather: $condition at ${temp}°C.";
          }
        }
      } catch (e) {
        debugPrint("Error loading weather info: $e");
      }
    }
    setState(() {
      _chatHistory.insert(0, {
        'sender': 'bot',
        'message':
            "Hi $_userFirstName, $_weatherInfo How can I assist you with your farm today?"
      }); // Add welcome message
    });
  }

  // Makes sure we can use the mic
  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  // Toggles speech-to-text on or off
  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(onResult: (result) {
          setState(() {
            _questionController.text = result.recognizedWords; // Fill text with voice input
          });
        });
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  // Hits the AI API for a response
  Future<void> _getAIResponse() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter a question")));
      return;
    }
    setState(() {
      _chatHistory.add({'sender': 'user', 'message': question});
      _isLoading = true; // Show loading bar
    });
    _questionController.clear();
    _scrollToBottom();

    String systemPrompt =
        "You are an expert AI assistant specialized in agriculture. Context: $_userContext. Also note: $_weatherInfo. Provide a direct, concise answer without any markdown formatting.";

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
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': question},
          ],
          'max_tokens': 200,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botResponse = data['choices'][0]['message']['content'].trim();
        setState(() {
          _chatHistory.add({'sender': 'bot', 'message': botResponse});
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _chatHistory.add({
            'sender': 'bot',
            'message': 'Error: Unable to get response. Please try again.'
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _chatHistory
            .add({'sender': 'bot', 'message': 'Error: ${e.toString()}'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Scrolls chat to the latest message
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Builds chat bubbles for user or bot
  Widget _buildChatBubble(Map<String, String> chat) {
    bool isUser = chat['sender'] == 'user';
    Alignment alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;
    Color bubbleColor =
        isUser ? Colors.grey[300]! : const Color.fromARGB(255, 66, 192, 201);
    TextStyle textStyle = isUser
        ? const TextStyle(color: Colors.black)
        : const TextStyle(color: Colors.white);
    EdgeInsets margin = isUser
        ? const EdgeInsets.only(top: 8, bottom: 8, left: 50, right: 8)
        : const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 50);
    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          chat['message']!,
          style: textStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            const Text('AI Farming Assistant', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_chatHistory[index]); // Show each message
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask a farming question...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic,
                      color: const Color.fromARGB(255, 66, 192, 201)),
                  onPressed: _startListening, // Toggle mic
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 66, 192, 201)),
                  onPressed: _isLoading ? null : _getAIResponse, // Send question
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 66, 192, 201)),
            ), // Loading bar when AI’s working
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _speech.stop();
    _scrollController.dispose();
    super.dispose(); // Clean up when we’re done
  }
}