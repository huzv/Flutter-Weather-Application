import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/weather_model.dart';

class HourlyForecastCard extends StatelessWidget {
  final HourlyForecast forecast;
  final bool isCelsius;
  final bool isNow;
  final bool currentIsDay;

  const HourlyForecastCard({
    super.key,
    required this.forecast,
    required this.isCelsius,
    this.isNow = false,
    this.currentIsDay = true,
  });

  String _formatTemp(double temp) {
    if (!isCelsius) {
      temp = (temp * 9 / 5) + 32;
    }
    return '${temp.round()}°';
  }

  String _formatHour(DateTime date) {
    if (isNow) return 'Now';
    int hour = date.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    int h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12 $period';
  }

  @override
  Widget build(BuildContext context) {
    final hour = forecast.date.hour;
    final bool isDay = isNow ? currentIsDay : (hour >= 6 && hour < 19);
    final icon = WeatherUtils.getWeatherIcon(
      forecast.weatherCode,
      isDay: isDay,
    );

    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatHour(forecast.date),
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            icon,
            width: 26,
            height: 26,
          ),
          const SizedBox(height: 8),
          Text(
            _formatTemp(forecast.temperature),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}