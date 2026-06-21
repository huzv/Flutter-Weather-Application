import 'package:flutter/material.dart';

class Location {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final double surfacePressure;
  final double visibility;
  final int isDay;

  CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.surfacePressure,
    required this.visibility,
    required this.isDay,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] ?? 0).toDouble(),
      apparentTemperature: (json['apparent_temperature'] ?? 0).toDouble(),
      humidity: json['relative_humidity_2m'] ?? 0,
      windSpeed: (json['wind_speed_10m'] ?? 0).toDouble(),
      weatherCode: json['weather_code'] ?? 0,
      surfacePressure: (json['pressure_msl'] ?? 0).toDouble(),
      visibility: (json['visibility'] ?? 0).toDouble(),
      isDay: json['is_day'] ?? 1,
    );
  }
}

class HourlyForecast {
  final DateTime date;
  final double temperature;
  final int weatherCode;

  HourlyForecast({
    required this.date,
    required this.temperature,
    required this.weatherCode,
  });
}

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
  final double precipitation;
  final String sunrise;
  final String sunset;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.precipitation,
    required this.sunrise,
    required this.sunset,
  });
}

class WeatherData {
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecast> hourly;

  WeatherData({
    required this.current,
    required this.daily,
    required this.hourly,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = CurrentWeather.fromJson(json['current'] ?? {});

    final dailyJson = json['daily'] ?? {};
    final List<dynamic> dailyTimes = dailyJson['time'] ?? [];
    final List<dynamic> maxTemps = dailyJson['temperature_2m_max'] ?? [];
    final List<dynamic> minTemps = dailyJson['temperature_2m_min'] ?? [];
    final List<dynamic> dailyCodes = dailyJson['weather_code'] ?? [];
    final List<dynamic> precipitations = dailyJson['precipitation_sum'] ?? [];
    final List<dynamic> sunrises = dailyJson['sunrise'] ?? [];
    final List<dynamic> sunsets = dailyJson['sunset'] ?? [];

    List<DailyForecast> daily = [];
    for (int i = 0; i < dailyTimes.length; i++) {
      daily.add(
        DailyForecast(
          date: DateTime.tryParse(dailyTimes[i].toString()) ?? DateTime.now(),
          maxTemp: (maxTemps.length > i ? maxTemps[i] ?? 0 : 0).toDouble(),
          minTemp: (minTemps.length > i ? minTemps[i] ?? 0 : 0).toDouble(),
          weatherCode: dailyCodes.length > i ? dailyCodes[i] ?? 0 : 0,
          precipitation:
              (precipitations.length > i ? precipitations[i] ?? 0 : 0)
                  .toDouble(),
          sunrise: sunrises.length > i ? sunrises[i]?.toString() ?? '' : '',
          sunset: sunsets.length > i ? sunsets[i]?.toString() ?? '' : '',
        ),
      );
    }

    final hourlyJson = json['hourly'] ?? {};
    final List<dynamic> hourlyTimes = hourlyJson['time'] ?? [];
    final List<dynamic> hourlyTemps = hourlyJson['temperature_2m'] ?? [];
    final List<dynamic> hourlyCodes = hourlyJson['weather_code'] ?? [];

    List<HourlyForecast> hourly = [];
    for (int i = 0; i < hourlyTimes.length; i++) {
      hourly.add(
        HourlyForecast(
          date: DateTime.tryParse(hourlyTimes[i].toString()) ?? DateTime.now(),
          temperature:
              (hourlyTemps.length > i ? hourlyTemps[i] ?? 0 : 0).toDouble(),
          weatherCode: hourlyCodes.length > i ? hourlyCodes[i] ?? 0 : 0,
        ),
      );
    }

    return WeatherData(current: current, daily: daily, hourly: hourly);
  }
}

class WeatherUtils {
  static String getWeatherLabel(int code) {
    if (code == 0) {
      return 'Clear';
    }
    if (code == 1) {
      return 'Mainly Clear';
    }
    if (code == 2) {
      return 'Partly Cloudy';
    }
    if (code == 3) {
      return 'Overcast';
    }
    if (code >= 45 && code <= 48) {
      return 'Foggy';
    }
    if (code >= 51 && code <= 55) {
      return 'Drizzle';
    }
    if (code >= 61 && code <= 65) {
      return 'Rain';
    }
    if (code >= 71 && code <= 75) {
      return 'Snow';
    }
    if (code >= 80 && code <= 82) {
      return 'Rain Showers';
    }
    if (code >= 85 && code <= 86) {
      return 'Snow Showers';
    }
    if (code == 95) {
      return 'Thunderstorm';
    }
    if (code == 99) {
      return 'Heavy Thunderstorm';
    }
    return 'Unknown';
  }

  static String getWeatherIcon(int code, {bool isDay = true}) {
    if (code == 0) {
      return isDay ? 'assets/weather/sunny.svg' : 'assets/weather/night.svg';
    }
    if (code == 1 || code == 2) {
      return isDay
          ? 'assets/weather/partly_cloudy.svg'
          : 'assets/weather/night.svg';
    }
    if (code == 3) {
      return 'assets/weather/cloud.svg';
    }
    if (code >= 45 && code <= 48) {
      return 'assets/weather/cloud.svg';
    }
    if (code >= 51 && code <= 55) {
      return 'assets/weather/drizzle.svg';
    }
    if (code >= 61 && code <= 65) {
      return 'assets/weather/rain.svg';
    }
    if (code >= 71 && code <= 75) {
      return 'assets/weather/snow.svg';
    }
    if (code >= 80 && code <= 82) {
      return 'assets/weather/rain.svg';
    }
    if (code >= 85 && code <= 86) {
      return 'assets/weather/snow.svg';
    }
    if (code == 95 || code == 99) {
      return 'assets/weather/storm.svg';
    }
    return 'assets/weather/cloud.svg';
  }

  static List<Color> getBackgroundColors(int code, int isDay) {
    if (isDay == 0) {
      return [const Color(0xFF0A1628), const Color(0xFF1E3A6B)];
    }
    if (code == 0 || code == 1) {
      return [const Color(0xFF1B3A5C), const Color(0xFF4A9AE6)];
    }
    if (code == 2 || code == 3) {
      return [const Color(0xFF4A5568), const Color(0xFF8D9BB0)];
    }
    if (code >= 45 && code <= 48) {
      return [const Color(0xFF4A5568), const Color(0xFF8B9DB5)];
    }
    if (code >= 51 && code <= 65) {
      return [const Color(0xFF1A2332), const Color(0xFF4E6480)];
    }
    if (code >= 71 && code <= 86) {
      return [const Color(0xFF4A5568), const Color(0xFFA8B8CC)];
    }
    if (code == 95 || code == 99) {
      return [const Color(0xFF0D1117), const Color(0xFF2B3139)];
    }
    return [const Color(0xFF1B3A5C), const Color(0xFF4A7FB5)];
  }

  static Color getTempColor(double tempC) {
    if (tempC <= 5) {
      return const Color(0xFF22D3EE);
    }
    if (tempC <= 12) {
      return const Color(0xFF4ADE80);
    }
    if (tempC <= 18) {
      return const Color(0xFFA3E635);
    }
    if (tempC <= 23) {
      return const Color(0xFFFBBF24);
    }
    if (tempC <= 28) {
      return const Color(0xFFF59E0B);
    }
    if (tempC <= 33) {
      return const Color(0xFFF97316);
    }
    return const Color(0xFFEF4444);
  }
}
