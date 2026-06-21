import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/weather_model.dart';
import 'forecast_card.dart';
import 'hourly_forecast_card.dart';

class WeatherView extends StatelessWidget {
  final Location currentLocation;
  final WeatherData weatherData;
  final bool isCelsius;
  final Future<void> Function() onRefresh;

  const WeatherView({
    super.key,
    required this.currentLocation,
    required this.weatherData,
    required this.isCelsius,
    required this.onRefresh,
  });

  String _formatTemp(double temp) {
    if (!isCelsius) {
      temp = (temp * 9 / 5) + 32;
    }
    return '${temp.round()}°';
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = weatherData.current;
    final daily = weatherData.daily.isNotEmpty ? weatherData.daily.first : null;
    final label = WeatherUtils.getWeatherLabel(current.weatherCode);
    final icon = WeatherUtils.getWeatherIcon(
      current.weatherCode,
      isDay: current.isDay == 1,
    );
    final now = DateTime.now();
    final upcomingHourly = weatherData.hourly
        .where((h) => h.date.isAfter(now.subtract(const Duration(hours: 1))))
        .take(24)
        .toList();

    double weeklyMin = 100;
    double weeklyMax = -100;
    for (final d in weatherData.daily) {
      if (d.minTemp < weeklyMin) {
        weeklyMin = d.minTemp;
      }
      if (d.maxTemp > weeklyMax) {
        weeklyMax = d.maxTemp;
      }
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: Colors.blueGrey,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currentLocation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SvgPicture.asset(
              icon,
              width: 72,
              height: 72,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTemp(current.temperature),
              style: const TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.w200,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            if (daily != null)
              Text(
                'H:${_formatTemp(daily.maxTemp)}  L:${_formatTemp(daily.minTemp)}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            const SizedBox(height: 30),
            if (upcomingHourly.isNotEmpty) _buildHourlyCard(upcomingHourly),
            _buildDailyCard(weeklyMin, weeklyMax),
            _buildDetailGrid(current, daily),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyCard(List<HourlyForecast> upcomingHourly) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOURLY FORECAST',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(color: Colors.white24),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: upcomingHourly.length,
              itemBuilder: (context, index) {
                return HourlyForecastCard(
                  forecast: upcomingHourly[index],
                  isCelsius: isCelsius,
                  isNow: index == 0,
                  currentIsDay: weatherData.current.isDay == 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(double weeklyMin, double weeklyMax) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-DAY FORECAST',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(color: Colors.white24),
          ...weatherData.daily.asMap().entries.map((entry) {
            return ForecastCard(
              forecast: entry.value,
              isCelsius: isCelsius,
              weeklyMin: weeklyMin,
              weeklyMax: weeklyMax,
              isToday: entry.key == 0,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(CurrentWeather current, DailyForecast? daily) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _tile(
          Icons.wb_twilight,
          'SUNRISE',
          daily != null ? _formatTime(daily.sunrise) : '--',
        ),
        _tile(
          Icons.nights_stay,
          'SUNSET',
          daily != null ? _formatTime(daily.sunset) : '--',
        ),
        _tile(
          Icons.air,
          'WIND',
          '${current.windSpeed.round()} km/h',
        ),
        _tile(
          Icons.water_drop,
          'RAINFALL',
          daily != null ? '${daily.precipitation.toStringAsFixed(1)} mm' : '--',
        ),
        _tile(
          Icons.thermostat,
          'FEELS LIKE',
          _formatTemp(current.apparentTemperature),
        ),
        _tile(Icons.opacity, 'HUMIDITY', '${current.humidity}%'),
        _tile(
          Icons.visibility,
          'VISIBILITY',
          '${(current.visibility / 1000).toStringAsFixed(0)} km',
        ),
        _tile(
          Icons.speed,
          'PRESSURE',
          '${current.surfacePressure.round()} hPa',
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 26),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty || !isoTime.contains('T')) return '--';
    final parts = isoTime.split('T');
    final timeParts = parts[1].split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }
}
