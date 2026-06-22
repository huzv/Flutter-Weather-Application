import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherBackground extends StatelessWidget {
  final WeatherData? weatherData;

  const WeatherBackground({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    List<Color> colors;
    if (weatherData == null) {
      colors = [const Color(0xFF1B3A5C), const Color(0xFF4A7FB5)];
    } else {
      colors = WeatherUtils.getBackgroundColors(
        weatherData!.current.weatherCode,
        weatherData!.current.isDay,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
    );
  }
}