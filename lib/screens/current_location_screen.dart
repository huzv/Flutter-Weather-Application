import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/weather_view.dart';

class CurrentLocationScreen extends StatefulWidget {
  final bool isCelsius;
  final void Function(WeatherData) onWeatherLoaded;

  const CurrentLocationScreen({
    super.key,
    required this.isCelsius,
    required this.onWeatherLoaded,
  });

  @override
  State<CurrentLocationScreen> createState() => _CurrentLocationScreenState();
}

class _CurrentLocationScreenState extends State<CurrentLocationScreen> {
  final WeatherService _weatherService = WeatherService();

  Location? _currentLocation;
  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();

      final weatherData = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      Location location;
      try {
        location = await _weatherService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        location = Location(
          name: 'My Location',
          country: '',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      if (mounted) {
        setState(() {
          _currentLocation = location;
          _weatherData = weatherData;
          _isLoading = false;
        });
        widget.onWeatherLoaded(weatherData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 56, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'Unable to Get Location',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchLocationAndWeather,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_weatherData == null || _currentLocation == null) {
      return const SizedBox();
    }

    return WeatherView(
      currentLocation: _currentLocation!,
      weatherData: _weatherData!,
      isCelsius: widget.isCelsius,
      onRefresh: _fetchLocationAndWeather,
    );
  }
}