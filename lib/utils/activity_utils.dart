import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';

final Schema jsonSchema = Schema.array(
  items: Schema.object(
    properties: {
      'title': Schema.string(),
      'description': Schema.string(),
      'photo_search_phrase': Schema.string(),
      'difficulty_level': Schema.integer(),
      'promotes_sustainability': Schema.boolean(),
      'requires_permit': Schema.boolean(),
      'is_active': Schema.boolean(),
      'has_fixed_location': Schema.boolean(),
      'url': Schema.string(),
      'category': Schema.string(),
    },
  ),
);

Future<List<dynamic>?> fetchActivitySuggestions(
  GenerativeModel activityModel,
  String userQuery,
  String weatherInfo,
  double latitude,
  double longitude,
  {String? currentTime,
  int numberOfActivities = 20} // Default to 20 for explore page
) async {
  final prompt = '''
    You are a Hawaii assistant chatbot. Provide a list of specific activities based on the current weather${currentTime != null ? ', time' : ''}, location, and user query.
    User Query: $userQuery
    Weather: $weatherInfo
    ${currentTime != null ? 'Current Time: $currentTime\n' : ''}
    Location: Latitude $latitude, Longitude $longitude
    Please include up to $numberOfActivities activities, depending on the scenario.
    Focus on specific local events, places to visit, and activities unique to the area.

    Prioritize the following categories of activities:
    - Hiking
    - Beach adventures
    - Camping
    - Cultural sites
    - Fishing
    - Local events
    - Sustainable activities

    Consider the weather conditions and time of day when suggesting activities. For example, suggest indoor activities if it's raining, or stargazing if it's nighttime.

    In terms of sustainability, aim to include a mix of activities that genuinely support environmental or community initiatives. Examples include:
    - Tree-planting eco-excursions
    - Conservation projects
    - Certified sustainable tour operators like Hawaii Forest & Trail on the Big Island or Kauaʻi Hiking Tours on Kauai
    - Operators dedicated to reef preservation
    - Volunteering opportunities such as beach cleanups or helping restore native forests

    Ensure that a reasonable portion of the activities suggested are sustainable, but do not over-tag activities as sustainable unless they meet the criteria.

    Favor activities that are accessible to a wide range of users and have clear instructions or guidance.

    Precise and detailed responses are encouraged to enhance the user's experience.
    E.g.: "Koko Head Hike" is better than "Go on a Hike".
    For each activity, if possible and relevant, provide a URL link to one of the following websites (State Agency or County Government websites):
    - oceansafety.hawaii.gov/*
    - *.hawaii.gov/*
    - *.ehawaii.gov/*
    - dlnr.hawaii.gov/*
    - hawaiitrails.ehawaii.gov/trails/*
    - outdoor.hawaii.gov/*
    - hawaiicounty.gov/*
    - kauai.gov/*
    - honolulu.gov/*
    - mauicounty.gov/*
    - *.gohawaii.com/*
    Do not link to other websites. If no URL is available, leave the field empty.
  ''';



  try {
    final response = await activityModel.generateContent([Content.text(prompt)]);
    if (response.text != null) {
      return json.decode(response.text!);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error getting activity suggestions from Vertex AI: $e');
    }
  }
  return null;
}
