import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/storage_service.dart';
import '../widgets/weather_view.dart';

class SearchScreen extends StatefulWidget {
  final bool isCelsius;
  final void Function(WeatherData) onWeatherLoaded;

  const SearchScreen({
    super.key,
    required this.isCelsius,
    required this.onWeatherLoaded,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final WeatherService _weatherService = WeatherService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<Location> _savedLocations = [];
  List<Location> _suggestions = [];
  bool _isLoadingSuggestions = false;
  bool _hasSearchFocus = false;

  Location? _currentLocation;
  WeatherData? _weatherData;
  bool _isLoading = false;
  bool _isViewingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _hasSearchFocus = _searchFocusNode.hasFocus;
    });
  }

  Future<void> _loadSavedLocations() async {
    final locations = await _storageService.getSavedLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    setState(() {
      _isLoadingSuggestions = value.trim().isNotEmpty;
      _suggestions = [];
    });

    if (value.trim().isEmpty) return;

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoadingSuggestions = true);

    try {
      final suggestions = await _weatherService.geocodeCitySuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Future<void> _selectSuggestion(Location location) async {
    _searchFocusNode.unfocus();
    _debounceTimer?.cancel();
    setState(() {
      _suggestions = [];
      _hasSearchFocus = false;
    });
    await _fetchWeather(existingLocation: location);
  }

  Future<void> _fetchWeather({Location? existingLocation}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty && existingLocation == null) return;

    setState(() {
      _isLoading = true;
      _isViewingWeather = true;
    });

    try {
      Location location;
      if (existingLocation != null) {
        location = existingLocation;
      } else {
        final loc = await _weatherService.geocodeCity(query);
        if (loc == null) {
          _showError('City not found. Please try another name.');
          setState(() {
            _isLoading = false;
            _isViewingWeather = false;
          });
          return;
        }
        location = loc;
      }

      final weatherData = await _weatherService.getWeather(
        location.latitude,
        location.longitude,
      );

      await _storageService.saveLocation(location);
      _loadSavedLocations();

      setState(() {
        _currentLocation = location;
        _weatherData = weatherData;
        _isLoading = false;
      });
      widget.onWeatherLoaded(weatherData);
    } catch (e) {
      _showError('Unable to fetch weather data. Please check your connection.');
      setState(() {
        _isLoading = false;
        _isViewingWeather = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isViewingWeather) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isViewingWeather = false;
                    _weatherData = null;
                    _searchController.clear();
                    _suggestions = [];
                  });
                },
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left, color: Colors.white),
                    Text(
                      'Back',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _weatherData != null
                ? WeatherView(
                    currentLocation: _currentLocation!,
                    weatherData: _weatherData!,
                    isCelsius: widget.isCelsius,
                    onRefresh: () =>
                        _fetchWeather(existingLocation: _currentLocation),
                  )
                : const SizedBox(),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Weather',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search for a city',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (_) {
              if (!_isLoading) {
                _fetchWeather();
              }
            },
          ),
          const SizedBox(height: 8),
          if (_shouldShowSuggestionsArea())
            _buildSuggestionsArea()
          else if (_savedLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No saved locations yet.\nSearch for a city to start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedLocations.length,
              itemBuilder: (context, index) {
                final loc = _savedLocations[index];
                return _buildLocationCard(loc);
              },
            ),
        ],
      ),
    );
  }

  bool _shouldShowSuggestionsArea() {
    return _hasSearchFocus || _searchController.text.trim().isNotEmpty;
  }

  Widget _buildSuggestionsArea() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return _buildSavedSuggestions();
    }

    if (_isLoadingSuggestions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No matching cities found.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    return _buildApiSuggestions();
  }

  Widget _buildSavedSuggestions() {
    if (_savedLocations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No saved locations yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _suggestionHeader('Saved Locations'),
        ..._savedLocations.map((loc) => _buildSuggestionTile(loc, isSaved: true)),
      ],
    );
  }

  Widget _buildApiSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _suggestionHeader('Suggestions'),
        ..._suggestions.map((loc) => _buildSuggestionTile(loc)),
      ],
    );
  }

  Widget _suggestionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(Location loc, {bool isSaved = false}) {
    return GestureDetector(
      onTap: () => _selectSuggestion(loc),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSaved ? Icons.location_on : Icons.search,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (loc.country.isNotEmpty)
                    Text(
                      loc.country,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Location loc) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _fetchWeather(existingLocation: loc);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.name,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                if (loc.country.isNotEmpty)
                  Text(
                    loc.country,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
              ],
            ),
            GestureDetector(
              onTap: () async {
                await _storageService.removeLocation(loc);
                _loadSavedLocations();
              },
              child: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}