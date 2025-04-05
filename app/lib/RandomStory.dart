import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RandomStory extends StatefulWidget {
  const RandomStory({super.key});

  @override
  State<RandomStory> createState() => _RandomStoryState();
}

class _RandomStoryState extends State<RandomStory> {
  final String apiKey = 'AIzaSyBF5WJL5t1shsuhfyV0Mw7YVkfK4_cXA9w'; // Replace with your real key
  late Future<String> _storyFuture;

  @override
  void initState() {
    super.initState();
    _storyFuture = getRandomStory();
  }

  Future<String> getRandomStory() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Write a short and imaginative random story suitable for kids.'}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text;
    } else {
      print("Error from Gemini API: ${response.body}");
      return "Failed to generate story.";
    }
  }

  void refreshStory() {
    setState(() {
      _storyFuture = getRandomStory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Random Story'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshStory,
            tooltip: 'Generate New Story',
          )
        ],
      ),
      body: FutureBuilder<String>(
        future: _storyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.data ?? 'No story found.',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }
}
