import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../widgets/weather_background.dart';
import 'current_location_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isCelsius = true;
  WeatherData? _myLocationWeatherData;
  WeatherData? _searchWeatherData;

  WeatherData? get _currentWeatherData {
    if (_currentIndex == 0) return _myLocationWeatherData;
    return _searchWeatherData ?? _myLocationWeatherData;
  }

  void _onMyLocationWeatherLoaded(WeatherData data) {
    setState(() {
      _myLocationWeatherData = data;
    });
  }

  void _onSearchWeatherLoaded(WeatherData data) {
    setState(() {
      _searchWeatherData = data;
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CurrentLocationScreen(
        isCelsius: _isCelsius,
        onWeatherLoaded: _onMyLocationWeatherLoaded,
      ),
      SearchScreen(
        isCelsius: _isCelsius,
        onWeatherLoaded: _onSearchWeatherLoaded,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          WeatherBackground(weatherData: _currentWeatherData),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isCelsius = !_isCelsius;
                        });
                      },
                      child: Text(
                        _isCelsius ? '°C' : '°F',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab(Icons.my_location, 'My Location', 0),
              _buildTab(Icons.list, 'Cities', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.55),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}