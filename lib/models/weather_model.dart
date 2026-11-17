import 'package:flutter/material.dart';

/// Represents a geographic location found via Open-Meteo Geocoding API.
class CityLocation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String country;
  final String? admin1;

  const CityLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.country,
    this.admin1,
  });

  String get displayName {
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      return '$name, $admin1, $country';
    }
    return '$name, $country';
  }

  factory CityLocation.fromJson(Map<String, dynamic> json) {
    return CityLocation(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String? ?? '',
      admin1: json['admin1'] as String?,
    );
  }
}

/// Represents a single hourly forecast item.
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final String condition;
  final IconData icon;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.icon,
  });
}

/// Represents a single daily forecast item (for 7-day forecast).
class DailyForecast {
  final DateTime date;
  final double maxTemperature;
  final double minTemperature;
  final int weatherCode;
  final String condition;
  final IconData icon;

  const DailyForecast({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.weatherCode,
    required this.condition,
    required this.icon,
  });
}

/// Complete weather data including current, hourly, and 7-day daily forecasts.
class WeatherData {
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final int relativeHumidity;
  final double windSpeed;
  final double surfacePressure;
  final double visibilityKm;
  final double uvIndex;
  final int weatherCode;
  final bool isDay;
  final String condition;
  final IconData icon;
  final double todayMaxTemp;
  final double todayMinTemp;
  final String sunrise;
  final String sunset;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.relativeHumidity,
    required this.windSpeed,
    required this.surfacePressure,
    required this.visibilityKm,
    required this.uvIndex,
    required this.weatherCode,
    required this.isDay,
    required this.condition,
    required this.icon,
    required this.todayMaxTemp,
    required this.todayMinTemp,
    required this.sunrise,
    required this.sunset,
    required this.hourly,
    required this.daily,
  });

  /// Factory constructor to parse Open-Meteo JSON payload.
  factory WeatherData.fromJson({
    required Map<String, dynamic> json,
    required String cityName,
    required String country,
  }) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final hourlyJson = json['hourly'] as Map<String, dynamic>? ?? {};
    final dailyJson = json['daily'] as Map<String, dynamic>? ?? {};

    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final isDay = (current['is_day'] as num?)?.toInt() == 1;

    // Parse Daily Forecasts
    final dailyTimes = (dailyJson['time'] as List<dynamic>?) ?? [];
    final dailyCodes = (dailyJson['weather_code'] as List<dynamic>?) ?? [];
    final dailyMaxs = (dailyJson['temperature_2m_max'] as List<dynamic>?) ?? [];
    final dailyMins = (dailyJson['temperature_2m_min'] as List<dynamic>?) ?? [];
    final dailySunrises = (dailyJson['sunrise'] as List<dynamic>?) ?? [];
    final dailySunsets = (dailyJson['sunset'] as List<dynamic>?) ?? [];
    final dailyUvs = (dailyJson['uv_index_max'] as List<dynamic>?) ?? [];

    final List<DailyForecast> dailyList = [];
    for (int i = 0; i < dailyTimes.length; i++) {
      final date = DateTime.tryParse(dailyTimes[i].toString()) ?? DateTime.now();
      final code = i < dailyCodes.length ? (dailyCodes[i] as num).toInt() : 0;
      final maxTemp = i < dailyMaxs.length ? (dailyMaxs[i] as num).toDouble() : 0.0;
      final minTemp = i < dailyMins.length ? (dailyMins[i] as num).toDouble() : 0.0;

      dailyList.add(DailyForecast(
        date: date,
        maxTemperature: maxTemp,
        minTemperature: minTemp,
        weatherCode: code,
        condition: getWeatherDescription(code),
        icon: getWeatherIcon(code, isDay: true),
      ));
    }

    // Today's High and Low
    final todayMax = dailyList.isNotEmpty ? dailyList.first.maxTemperature : (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final todayMin = dailyList.isNotEmpty ? dailyList.first.minTemperature : (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;

    // Parse Hourly Forecasts
    final hourlyTimes = (hourlyJson['time'] as List<dynamic>?) ?? [];
    final hourlyTemps = (hourlyJson['temperature_2m'] as List<dynamic>?) ?? [];
    final hourlyCodes = (hourlyJson['weather_code'] as List<dynamic>?) ?? [];
    final hourlyVisibilities = (hourlyJson['visibility'] as List<dynamic>?) ?? [];
    final hourlyUvs = (hourlyJson['uv_index'] as List<dynamic>?) ?? [];

    final currentTimeStr = current['time'] as String? ?? '';
    final parsedCurrentTime = DateTime.tryParse(currentTimeStr) ?? DateTime.now();

    final List<HourlyForecast> hourlyList = [];
    double currentVisibility = 10.0; // default 10 km
    double currentUv = dailyUvs.isNotEmpty ? (dailyUvs.first as num).toDouble() : 0.0;

    // Find the current hour index or start from now
    int startIndex = 0;
    for (int i = 0; i < hourlyTimes.length; i++) {
      final hourTime = DateTime.tryParse(hourlyTimes[i].toString());
      if (hourTime != null) {
        if (hourTime.isAfter(parsedCurrentTime) ||
            (hourTime.year == parsedCurrentTime.year &&
                hourTime.month == parsedCurrentTime.month &&
                hourTime.day == parsedCurrentTime.day &&
                hourTime.hour == parsedCurrentTime.hour)) {
          startIndex = i;
          if (i < hourlyVisibilities.length && hourlyVisibilities[i] != null) {
            currentVisibility = (hourlyVisibilities[i] as num).toDouble() / 1000.0;
          }
          if (i < hourlyUvs.length && hourlyUvs[i] != null) {
            currentUv = (hourlyUvs[i] as num).toDouble();
          }
          break;
        }
      }
    }

    // Grab next 24 hours of forecast
    final endIndex = (startIndex + 24).clamp(0, hourlyTimes.length);
    for (int i = startIndex; i < endIndex; i++) {
      final time = DateTime.tryParse(hourlyTimes[i].toString()) ?? DateTime.now();
      final temp = i < hourlyTemps.length ? (hourlyTemps[i] as num).toDouble() : 0.0;
      final code = i < hourlyCodes.length ? (hourlyCodes[i] as num).toInt() : 0;
      final hourIsDay = time.hour >= 6 && time.hour < 18;

      hourlyList.add(HourlyForecast(
        time: time,
        temperature: temp,
        weatherCode: code,
        condition: getWeatherDescription(code),
        icon: getWeatherIcon(code, isDay: hourIsDay),
      ));
    }

    // Sunrise & Sunset formatted string
    final rawSunrise = dailySunrises.isNotEmpty ? dailySunrises.first.toString() : '';
    final rawSunset = dailySunsets.isNotEmpty ? dailySunsets.first.toString() : '';

    return WeatherData(
      cityName: cityName,
      country: country,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      time: parsedCurrentTime,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      surfacePressure: (current['surface_pressure'] as num?)?.toDouble() ?? 1013.0,
      visibilityKm: currentVisibility,
      uvIndex: currentUv,
      weatherCode: weatherCode,
      isDay: isDay,
      condition: getWeatherDescription(weatherCode),
      icon: getWeatherIcon(weatherCode, isDay: isDay),
      todayMaxTemp: todayMax,
      todayMinTemp: todayMin,
      sunrise: formatTimeString(rawSunrise),
      sunset: formatTimeString(rawSunset),
      hourly: hourlyList,
      daily: dailyList,
    );
  }

  /// Converts ISO time string like "2026-11-17T06:42" to "6:42 AM".
  static String formatTimeString(String isoString) {
    if (isoString.isEmpty) return '--:--';
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) return isoString;

    final hour = parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$hour12:$minute $period';
  }

  /// WMO Weather Code to human-readable description mapping.
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Foggy';
      case 48:
        return 'Depositing Rime Fog';
      case 51:
        return 'Light Drizzle';
      case 53:
        return 'Moderate Drizzle';
      case 55:
        return 'Dense Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
        return 'Slight Rain';
      case 63:
        return 'Moderate Rain';
      case 65:
        return 'Heavy Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
        return 'Slight Snow';
      case 73:
        return 'Moderate Snow';
      case 75:
        return 'Heavy Snow';
      case 77:
        return 'Snow Grains';
      case 80:
        return 'Slight Showers';
      case 81:
        return 'Moderate Showers';
      case 82:
        return 'Violent Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with Hail';
      default:
        return 'Clear Sky';
    }
  }

  /// WMO Weather Code to Material Icon mapping.
  static IconData getWeatherIcon(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
      case 1:
        return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_round;
      case 2:
        return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_outlined;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icons.grain_rounded;
      case 61:
      case 63:
        return Icons.water_drop_rounded;
      case 65:
      case 66:
      case 67:
        return Icons.umbrella_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 80:
      case 81:
      case 82:
        return Icons.shower_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return isDay ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded;
    }
  }
}

