import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types; // Import this package
import 'chat_screen.dart';
import 'explore_page.dart';
import '../utils/activity_utils.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  State<TabNavigation> createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  final PageController _pageController = PageController();
  List<dynamic> _activities = [];
  late final GenerativeModel activityModel;
  final List<types.Message> _chatMessages = []; // Preserve chat messages

  @override
  void initState() {
    super.initState();
    _initializeActivityModel();
  }

  Future<void> _initializeActivityModel() async {
    activityModel = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
    );
    _fetchInitialActivities();
  }

  Future<void> _fetchInitialActivities() async {
    final activities = await fetchActivitySuggestions(
        activityModel,
        "Explore activities",
        "Weather info",
        21.3069,
        -157.8583,
        numberOfActivities: 20 // Fetch more activities for explore page
    );
    if (activities != null) {
      setState(() {
        _activities = activities;
      });
    }
  }

  void _resetChat() {
    setState(() {
      _chatMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore & Chat'),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          ExplorePage(activities: _activities),
          ChatScreenPage(
            messages: _chatMessages,
            onReset: _resetChat,
          ),
        ],
      ),
    );
  }
}