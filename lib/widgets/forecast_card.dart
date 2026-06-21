import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/weather_model.dart';

class ForecastCard extends StatelessWidget {
  final DailyForecast forecast;
  final bool isCelsius;
  final double weeklyMin;
  final double weeklyMax;
  final bool isToday;

  const ForecastCard({
    super.key,
    required this.forecast,
    required this.isCelsius,
    required this.weeklyMin,
    required this.weeklyMax,
    this.isToday = false,
  });

  String _formatTemp(double temp) {
    if (!isCelsius) {
      temp = (temp * 9 / 5) + 32;
    }
    return '${temp.round()}°';
  }

  String _getDayName(DateTime date) {
    if (isToday) {
      return 'Today';
    }
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dayName = _getDayName(forecast.date);
    final icon = WeatherUtils.getWeatherIcon(forecast.weatherCode);

    final totalRange = weeklyMax - weeklyMin;
    final double startFraction =
        totalRange > 0 ? (forecast.minTemp - weeklyMin) / totalRange : 0.0;
    final double endFraction =
        totalRange > 0 ? (forecast.maxTemp - weeklyMin) / totalRange : 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              dayName,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: SvgPicture.asset(
              icon,
              width: 22,
              height: 22,
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              _formatTemp(forecast.minTemp),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildBar(startFraction, endFraction)),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(
              _formatTemp(forecast.maxTemp),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double startFraction, double endFraction) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final barStart = startFraction * totalWidth;
        final barEnd = endFraction * totalWidth;
        final barWidth = (barEnd - barStart).clamp(6.0, totalWidth);

        return Stack(
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: barStart),
              child: Container(
                width: barWidth,
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      WeatherUtils.getTempColor(forecast.minTemp),
                      WeatherUtils.getTempColor(forecast.maxTemp),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
