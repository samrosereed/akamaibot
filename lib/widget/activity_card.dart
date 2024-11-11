import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/api_utils.dart';

class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final FlutterTts flutterTts = FlutterTts();

  ActivityCard({super.key, required this.activity});

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showFullPageActivity(context, activity);
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
              FutureBuilder<String?>(
                future: fetchImageFromPexels(activity['photo_search_phrase']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Icon(Icons.error, color: Colors.red));
                  } else {
                    return CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                    );
                  }
                },
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8), // Darker gradient
                        Colors.black.withOpacity(0.6),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPageActivity(BuildContext context, Map<String, dynamic> activity) async {
    const origin = '21.3069,-157.8583'; // Example origin, replace with actual user location
    String? travelTime;
    if (activity['has_fixed_location'] == true) {
      travelTime = await fetchTravelTime(origin, activity['title']);
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        appBar: AppBar(title: Text(activity['title'])),
        body: Column(
          children: [
            FutureBuilder<String?>(
              future: fetchImageFromPexels(activity['photo_search_phrase']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Icon(Icons.error, color: Colors.red));
                } else {
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(activity['description']),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.black),
              onPressed: () => _speak('${activity['title']}. ${activity['description']}'),
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
            if (activity['is_active'] == true && activity['difficulty_level'] != null)
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
                        style: TextStyle(color: Colors.blue, fontSize: 16, decoration: TextDecoration.underline),
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
}
