import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widget/chat_message.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/activity_utils.dart';
import '../utils/api_utils.dart';

class ChatScreenPage extends StatefulWidget {
  final List<types.Message> messages;
  final VoidCallback onReset;

  const ChatScreenPage({super.key, required this.messages, required this.onReset});

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final types.User user = const types.User(id: 'user-id');
  final Uuid uuid = const Uuid();

  // Create a User object for the bot with an avatar
  final types.User botUser = const types.User(
    id: 'bot-id',
    firstName: 'Bot',
    imageUrl: 'assets/images/ai_avatar.jpeg',
  );

  late final GenerativeModel model;
  late final GenerativeModel activityModel;
  late final ChatSession vertexChatSession;
  bool _isModelInitialized = false;
  bool _welcomeMessageAdded = false;
  Position? _currentPosition;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndVertexAI();
    _requestPermissions();
    _addWelcomeMessage();
  }

  Future<void> _initializeFirebaseAndVertexAI() async {
    await Firebase.initializeApp();
    try {
      if (kDebugMode) {
        print('Initializing Vertex AI models...');
      }
      model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
      );

      activityModel = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: jsonSchema,
        ),
      );

      vertexChatSession = model.startChat();

      setState(() {
        _isModelInitialized = true;
      });
      if (kDebugMode) {
        print('Vertex AI models initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Vertex AI models: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
      Permission.photos,
    ].request();

    _currentPosition = await _determinePosition();
  }

  void _addWelcomeMessage() {
    if (!_welcomeMessageAdded) { // Check if the welcome message has already been added
      final welcomeMessage = types.TextMessage(
        author: botUser,
        // Use the bot user with an avatar
        createdAt: DateTime
            .now()
            .millisecondsSinceEpoch,
        id: uuid.v4(),
        text: 'Aloha, welcome to the chat!',
        metadata: const {'isBot': true},
      );

      setState(() {
        widget.messages.insert(0, welcomeMessage);
        _welcomeMessageAdded =
        true; // Set the flag to true to prevent further additions
      });
    }
  }

  void handleSendPressed(types.PartialText message) async {
    if (!_isModelInitialized) {
      if (kDebugMode) {
        print('Model not initialized yet.');
      }
      return;
    }

    final userMessage = types.TextMessage(
      author: user,
      createdAt: DateTime
          .now()
          .millisecondsSinceEpoch,
      id: uuid.v4(),
      text: message.text,
    );

    setState(() {
      widget.messages.insert(0, userMessage);
    });

    if (_isActivityQuery(message.text)) {
      final latitude = _currentPosition?.latitude ?? 21.3069;
      final longitude = _currentPosition?.longitude ?? -157.8583;
      final weatherInfo = await fetchWeatherData(latitude, longitude) ??
          'No weather data available.';
      final currentTime = DateTime.now().toIso8601String();

      final activities = await fetchActivitySuggestions(
          activityModel,
          message.text,
          weatherInfo,
          latitude,
          longitude,
          currentTime: currentTime,
          numberOfActivities: 5 // Fetch fewer, more tailored activities for chat
      );

      if (activities != null) {
        _addActivityCardsToChat(activities);
      } else {
        _addBotResponse(
            'Sorry, I could not find any activity suggestions at the moment.');
      }
    } else {
      _getChatResponse(message.text);
    }
  }

  bool _isActivityQuery(String text) {
    return RegExp(
        r'\b(what can I do here|things to do today|activity suggestions|give me ideas of what I can do today|activities)\b',
        caseSensitive: false)
        .hasMatch(text);
  }

  Future<void> _getChatResponse(String userInput) async {
    final prompt = '''
  You are a Hawaii assistant chatbot whose primary function is to provide information about Hawaii.
  Rules:
  • Assume the user is interested in learning more about Hawaii and is currently in the State.
  • Be friendly and informative in all interactions.
  • You may use pleasantries but keep the conversation focused on Hawaii.
  • If the user asks anything unrelated to Hawaii, respond, "I am a chatbot who only provides information related to Hawaii."
  • If the user asks about locations or topics without specifying, assume they are referring to Hawaii.
  • Aim to enhance the user's understanding and experience by providing insightful, concise, and helpful responses.
  • Suggest picturesque locations and highlight local customs and traditions to enrich the user's knowledge.
  • Always strive to keep the information relevant to Hawaii and its unique offerings.

  User: $userInput
  Assistant:
  ''';

    try {
      final response = await vertexChatSession.sendMessage(
          Content.text(prompt));
      if (response.text != null) {
        _addBotResponse(response.text!);
      } else {
        _addBotResponse('Sorry, I could not understand that.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting chat response from Vertex AI: $e');
      }
      _addBotResponse('There was an error processing your request.');
    }
  }

  void _addActivityCardsToChat(List<dynamic> activities) async {
  final List<Widget> pages = [];

  for (var activity in activities) {
    final imageUrl = await fetchImageFromPexels(activity['photo_search_phrase']);
    pages.add(
      GestureDetector(
        onTap: () {
          _showFullPageActivity(activity, imageUrl);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                if (imageUrl != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'],
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        if (activity['promotes_sustainability'] == true)
                          const Text(
                            'Mālama Hawaiʻi',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 14),
                          ),
                        if (activity['is_active'] == true && activity['difficulty_level'] != null)
                          Text(
                            'Difficulty Level: ${activity['difficulty_level']}/5',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final pageController = PageController();

  // Check if a similar activity message already exists
  if (widget.messages.any((msg) => msg is types.CustomMessage && msg.metadata?['pages'] == pages)) {
    return; // Avoid adding duplicates
  }

  setState(() {
    widget.messages.insert(
      0,
      types.CustomMessage(
        author: const types.User(id: 'bot-id', firstName: 'Bot'),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: uuid.v4(),
        metadata: {'pages': pages},
      ),
    );
  });
}

  void _showFullPageActivity(dynamic activity, String? imageUrl) async {
    final origin = '${_currentPosition?.latitude ?? 21.3069},${_currentPosition
        ?.longitude ?? -157.8583}';
    String? travelTime;
    if (activity['has_fixed_location'] == true) {
      travelTime = await fetchTravelTime(origin, activity['title']);
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(activity['title'])),
        body: Column(
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Icon(Icons.error, color: Colors.red),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(activity['description']),
            ),
            if (activity['promotes_sustainability'] == true)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Supports Hawaiʻi's communities & islands.",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (activity['is_active'] == true &&
                activity['difficulty_level'] != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.terrain, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Difficulty Level: ${activity['difficulty_level']}/5',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (travelTime != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      travelTime,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            if (activity['url'] != null && activity['url'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(activity['url']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (kDebugMode) {
                            print('Could not launch $url');
                          }
                        }
                      },
                      child: const Text(
                        'More Information',
                        style: TextStyle(color: Colors.blue,
                            fontSize: 16,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }));
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  void _addBotResponse(String responseText) {
    final botMessage = types.TextMessage(
      author: botUser,
      createdAt: DateTime
          .now()
          .millisecondsSinceEpoch,
      id: uuid.v4(),
      text: responseText,
      metadata: const {'isBot': true},
    );

    setState(() {
      widget.messages.insert(0, botMessage);
    });
  }

  Widget _customMessageBuilder(types.Message message,
      {required int messageWidth}) {
    if (message is types.TextMessage) {
      return ChatMessage(
        message: message,
      );
    } else if (message is types.CustomMessage) {
      final pages = message.metadata!['pages'] as List<Widget>;
      final pageController = PageController();

      return Column(
        children: [
          SizedBox(
            height: 300, // Adjust the height as needed
            child: PageView(
              controller: pageController,
              children: pages,
            ),
          ),
          SmoothPageIndicator(
            controller: pageController,
            count: pages.length,
            effect: const WormEffect(
              dotWidth: 8.0,
              dotHeight: 8.0,
              activeDotColor: Colors.blueAccent,
              dotColor: Colors.grey,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('akamAI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onReset,
          ),
        ],
      ),
      body: _isModelInitialized
          ? Column(
        children: [
          Expanded(
            child: Chat(
              messages: widget.messages,
              onSendPressed: handleSendPressed,
              user: user,
              l10n: const ChatL10nEn(
                inputPlaceholder: "Hawai'i activities? Ask me anything! 🌺",
              ),
              customMessageBuilder: _customMessageBuilder,
              showUserAvatars: true,
              theme: DefaultChatTheme(
                backgroundColor: Color(0xFF121212),
                // Dark background
                inputBackgroundColor: Color(0xFF1E1E1E),
                // Darker input field
                inputTextColor: Colors.white,
                inputTextCursorColor: Color.fromRGBO(255, 170, 51, 1),
                // Yellow
                inputBorderRadius: BorderRadius.circular(8.0),
                primaryColor: Color.fromRGBO(0, 202, 218, 1),
                // Blue for sent messages
                secondaryColor: Colors.white24,
                // Pink for received messages
                sentMessageBodyTextStyle: TextStyle(color: Colors.white),
                receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      )
          : const Center(
          child: CircularProgressIndicator()), // Show loading indicator
    );
  }
}