import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> fetchWeatherData(double latitude, double longitude) async {
  const userAgent = 'akamAI/0.4.0 (your.email@example.com)';
  final gridpointUrl = Uri.parse('https://api.weather.gov/points/$latitude,$longitude');

  try {
    final gridpointResponse = await http.get(gridpointUrl, headers: {'User-Agent': userAgent});
    if (gridpointResponse.statusCode == 200) {
      final gridpointData = json.decode(gridpointResponse.body);
      final gridId = gridpointData['properties']['gridId'];
      final gridX = gridpointData['properties']['gridX'];
      final gridY = gridpointData['properties']['gridY'];

      final forecastUrl = Uri.parse('https://api.weather.gov/gridpoints/$gridId/$gridX,$gridY/forecast');
      final forecastResponse = await http.get(forecastUrl, headers: {'User-Agent': userAgent});
      if (forecastResponse.statusCode == 200) {
        final forecastData = json.decode(forecastResponse.body);
        final periods = forecastData['properties']['periods'];
        final currentPeriod = periods[0];
        return 'Weather forecast for ${currentPeriod['name']}: ${currentPeriod['detailedForecast']}';
      } else {
        return 'Could not fetch weather forecast.';
      }
    } else {
      return 'Could not fetch gridpoint information.';
    }
  } catch (e) {
    return 'Error fetching weather data: $e';
  }
}

Future<String?> fetchImageFromPexels(String query) async {
  const apiKey = 'dgBOfoSawLSkiW4rhEfZoCnZUcUPvVxTgdPyyuOxKp5u2x86xop4ZaPM'; // Ensure you have a valid API key
  final url = Uri.parse('https://api.pexels.com/v1/search?query=$query&per_page=1');

  try {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(query);
    if (cachedUrl != null) {
      // Return cached URL if available
      return cachedUrl;
    }

    final response = await http.get(url, headers: {'Authorization': apiKey});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['photos'].isNotEmpty) {
        final photo = data['photos'][0];
        final imageUrl = photo['src']['large'];
        // Cache the URL
        await prefs.setString(query, imageUrl);
        return imageUrl;
      } else {
        if (kDebugMode) {
          print('No photos found for query: $query');
        }
        return null;
      }
    } else if (response.statusCode == 429) {
      if (kDebugMode) {
        print('Rate limit exceeded. Please try again later.');
      }
      // Implement a retry strategy or inform the user
      return null;
    } else {
      if (kDebugMode) {
        print('Error fetching image: ${response.statusCode}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching image: $e');
    }
    return null;
  }
}

Future<String?> fetchTravelTime(String origin, String destination) async {
  const apiKey = 'AIzaSyDFRcXcu3y8qYP52PlQVnUw4Vx1paiJpxc'; // Ensure you have a valid API key
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey&departure_time=now');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'] as List;
      if (routes.isNotEmpty) {
        final legs = routes[0]['legs'] as List;
        if (legs.isNotEmpty) {
          final duration = legs[0]['duration']['text'];
          final durationInTraffic = legs[0]['duration_in_traffic']['text'];
          return 'Travel time: $duration (Traffic: $durationInTraffic)';
        }
      }
      return 'Could not fetch travel time data.';
    } else {
      return 'Travel time data request failed.';
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching travel time: $e');
    }
    return null;
  }
}
