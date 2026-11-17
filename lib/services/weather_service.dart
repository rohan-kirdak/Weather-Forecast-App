import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

/// Custom exception for weather service errors.
class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Default city when application starts (Pune, India).
  static const CityLocation defaultCity = CityLocation(
    id: 1259229,
    name: 'Pune',
    latitude: 18.5204,
    longitude: 73.8567,
    country: 'India',
    admin1: 'Maharashtra',
  );

  /// Searches for cities worldwide using Open-Meteo Geocoding API.
  Future<List<CityLocation>> searchCities(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$_geocodingBaseUrl?name=${Uri.encodeComponent(trimmedQuery)}&count=6&language=en&format=json',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('results') && data['results'] is List) {
          final List<dynamic> results = data['results'];
          return results.map((item) => CityLocation.fromJson(item)).toList();
        }
        return [];
      } else {
        throw WeatherException('Server returned error ${response.statusCode}');
      }
    } on SocketException {
      throw const WeatherException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw const WeatherException('Connection timed out. Please try again.');
    } on http.ClientException {
      throw const WeatherException('Unable to reach server. Please check your network.');
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Search failed: $e');
    }
  }

  /// Fetches real-time weather, hourly, and 7-day daily forecasts.
  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
    required String cityName,
    required String country,
  }) async {
    final uri = Uri.parse(
      '$_forecastBaseUrl?'
      'latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,is_day'
      '&hourly=temperature_2m,weather_code,visibility,uv_index'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max'
      '&timezone=auto',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return WeatherData.fromJson(
          json: data,
          cityName: cityName,
          country: country,
        );
      } else {
        throw WeatherException(
          'Weather service returned error code ${response.statusCode}.',
        );
      }
    } on SocketException {
      throw const WeatherException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw const WeatherException('Connection timed out. Please try again.');
    } on http.ClientException {
      throw const WeatherException('Network request failed. Please check your connection.');
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Failed to load weather: $e');
    }
  }
}

