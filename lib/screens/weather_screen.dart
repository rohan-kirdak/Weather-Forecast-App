import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/detail_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/hour_card.dart';
import '../widgets/sun_card.dart';

class WeatherScreen extends StatefulWidget {
  final WeatherService? weatherService;

  const WeatherScreen({this.weatherService, super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const Color _bgStart = Color(0xFF101D40);
  static const Color _bgMid = Color(0xFF102F59);
  static const Color _bgEnd = Color(0xFF07152D);
  static const Color _white = Colors.white;
  static const Color _muted = Color(0xFFB4C5DE);
  static const Color _yellow = Color(0xFFFFC66D);

  late final WeatherService _weatherService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  WeatherData? _weatherData;
  CityLocation _selectedCity = WeatherService.defaultCity;
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  List<CityLocation> _searchResults = [];
  Timer? _debounceTimer;

  static const List<String> _weekdaysUpper = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  static const List<String> _monthsUpper = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  @override
  void initState() {
    super.initState();
    _weatherService = widget.weatherService ?? WeatherService();
    _loadWeatherForCity(_selectedCity);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Fetches weather data for a specified city location.
  Future<void> _loadWeatherForCity(CityLocation city) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults = [];
    });

    try {
      final data = await _weatherService.fetchWeather(
        latitude: city.latitude,
        longitude: city.longitude,
        cityName: city.name,
        country: city.country,
      );

      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _selectedCity = city;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Handles search query input with debouncing to prevent excessive API calls.
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      try {
        final results = await _weatherService.searchCities(trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  /// Handles search submission when user presses Enter on keyboard.
  Future<void> _onSearchSubmitted(String query) async {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _searchFocusNode.unfocus();
    setState(() => _isSearching = true);

    try {
      final results = await _weatherService.searchCities(trimmed);
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });

      if (results.isNotEmpty) {
        _searchController.clear();
        await _loadWeatherForCity(results.first);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E3A66),
            content: Text(
              'No city found matching "$trimmed". Please try another search.',
              style: const TextStyle(color: _white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF661E1E),
          content: Text(
            'Search error: $e',
            style: const TextStyle(color: _white),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectSearchResult(CityLocation city) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
    _loadWeatherForCity(city);
  }

  String _formatHeroDate(DateTime dt) {
    final weekday = _weekdaysUpper[dt.weekday - 1];
    final month = _monthsUpper[dt.month - 1];
    return '$weekday, ${dt.day} $month';
  }

  String _getHumiditySubtitle(int humidity) {
    if (humidity < 30) return 'Low humidity';
    if (humidity <= 60) return 'Comfortable';
    if (humidity <= 80) return 'Humid';
    return 'Very humid';
  }

  String _getWindSubtitle(double speed) {
    if (speed < 5) return 'Calm';
    if (speed < 20) return 'Light breeze';
    if (speed < 40) return 'Moderate wind';
    return 'Strong wind';
  }

  String _getFeelsLikeSubtitle(double actual, double feelsLike) {
    final diff = feelsLike - actual;
    if (diff.abs() <= 1.0) return 'Similar to actual';
    if (diff > 1.0) return 'Feels warmer';
    return 'Feels cooler';
  }

  String _getUvSubtitle(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very high';
    return 'Extreme';
  }

  String _getVisibilitySubtitle(double km) {
    if (km >= 10) return 'Very clear';
    if (km >= 5) return 'Good visibility';
    if (km >= 2) return 'Moderate visibility';
    return 'Poor visibility';
  }

  String _getPressureSubtitle(double hPa) {
    if (hPa > 1020) return 'High pressure';
    if (hPa < 1005) return 'Low pressure';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08152E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMid, _bgEnd],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _yellow,
            backgroundColor: const Color(0xFF193B70),
            onRefresh: () => _loadWeatherForCity(_selectedCity),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 750;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            _buildHeader(),

                            const SizedBox(height: 25),

                            // CITY SEARCH BAR & SUGGESTIONS
                            _buildSearchBar(),

                            if (_searchResults.isNotEmpty)
                              _buildSearchSuggestionsOverlay(),

                            const SizedBox(height: 25),

                            // CONTENT OR LOADING / ERROR
                            if (_isLoading && _weatherData == null)
                              _buildLoadingIndicator()
                            else if (_errorMessage != null && _weatherData == null)
                              _buildErrorView()
                            else if (_weatherData != null)
                              _buildWeatherContent(wide),

                            const SizedBox(height: 35),

                            // FOOTER
                            Center(
                              child: Text(
                                'WEATHERLY  •  POWERED BY OPEN-METEO',
                                style: TextStyle(
                                  color: _muted.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.cloud_rounded, color: _yellow, size: 32),
        const SizedBox(width: 10),
        const Text(
          'Weatherly',
          style: TextStyle(
            color: _white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        const Spacer(),
        Flexible(
          child: _buildLocationBadge(),
        ),
      ],
    );
  }

  Widget _buildLocationBadge() {
    return InkWell(
      onTap: () => _loadWeatherForCity(_selectedCity),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: _yellow, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _selectedCity.displayName,
                style: const TextStyle(
                  color: _white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.refresh,
              color: _muted.withValues(alpha: 0.8),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _white.withValues(alpha: 0.14)),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        style: const TextStyle(color: _white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search city worldwide (e.g. London, Tokyo, New York)...',
          hintStyle: const TextStyle(color: _muted, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _muted),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _yellow,
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: _muted, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                )
              else
                IconButton(
                  tooltip: 'Reset to default (Pune)',
                  icon: const Icon(Icons.my_location, color: _yellow, size: 20),
                  onPressed: () {
                    _searchFocusNode.unfocus();
                    _searchController.clear();
                    _loadWeatherForCity(WeatherService.defaultCity);
                  },
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestionsOverlay() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF132B52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: _white.withValues(alpha: 0.08),
          ),
          itemBuilder: (context, index) {
            final city = _searchResults[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_city, color: _yellow, size: 20),
              title: Text(
                city.name,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                city.displayName,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: _muted,
                size: 13,
              ),
              onTap: () => _selectSearchResult(city),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _yellow),
          SizedBox(height: 20),
          Text(
            'Fetching latest weather...',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFFF8E8E),
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to Load Weather',
            style: TextStyle(
              color: _white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'An unexpected error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadWeatherForCity(_selectedCity),
            icon: const Icon(Icons.refresh, color: Color(0xFF08152E)),
            label: const Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFF08152E),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(bool wide) {
    final weather = _weatherData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HERO CARD
        _buildHeroCard(weather, wide),

        const SizedBox(height: 32),

        // HOURLY FORECAST
        _sectionTitle('Hourly Forecast', 'Next 24 hours'),
        const SizedBox(height: 16),
        _buildHourlyForecast(weather),

        const SizedBox(height: 32),

        // 7-DAY FORECAST
        _sectionTitle('7-Day Forecast', 'Weekly outlook'),
        const SizedBox(height: 16),
        _buildDailyForecast(weather),

        const SizedBox(height: 32),

        // WEATHER DETAILS
        _sectionTitle('Weather Details', 'Current conditions'),
        const SizedBox(height: 16),
        _buildWeatherDetails(weather),

        const SizedBox(height: 32),

        // SUNRISE & SUNSET
        _sectionTitle('Sunrise & Sunset', 'Today'),
        const SizedBox(height: 16),
        _buildSunriseSunset(weather),
      ],
    );
  }

  Widget _buildHeroCard(WeatherData weather, bool wide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF315F9B), Color(0xFF193B70), Color(0xFF182B54)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _white.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(flex: 3, child: _buildHeroLocation(weather)),
                Expanded(flex: 4, child: _buildHeroMain(weather)),
                Expanded(flex: 3, child: _buildHeroHighLow(weather)),
              ],
            )
          : Column(
              children: [
                _buildHeroLocation(weather),
                const SizedBox(height: 20),
                _buildHeroMain(weather),
                const SizedBox(height: 16),
                _buildHeroHighLow(weather),
              ],
            ),
    );
  }

  Widget _buildHeroLocation(WeatherData weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatHeroDate(weather.time),
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          weather.cityName,
          style: const TextStyle(
            color: _white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          weather.country,
          style: const TextStyle(color: _muted, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildHeroMain(WeatherData weather) {
    return Column(
      children: [
        Icon(weather.icon, size: 90, color: _yellow),
        const SizedBox(height: 6),
        Text(
          '${weather.temperature.round()}°C',
          style: const TextStyle(
            color: _white,
            fontSize: 64,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          weather.condition,
          style: const TextStyle(
            color: _muted,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHighLow(WeatherData weather) {
    return Column(
      children: [
        const Text(
          'HIGH / LOW',
          style: TextStyle(
            color: _muted,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${weather.todayMaxTemp.round()}° / ${weather.todayMinTemp.round()}°',
          style: const TextStyle(
            color: _white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Feels like ${weather.apparentTemperature.round()}°',
          style: const TextStyle(color: _muted, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(WeatherData weather) {
    if (weather.hourly.isEmpty) {
      return const Text(
        'Hourly forecast unavailable',
        style: TextStyle(color: _muted),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(weather.hourly.length, (index) {
          final item = weather.hourly[index];
          final isFirst = index == 0;
          final timeLabel = isFirst
              ? 'Now'
              : WeatherData.formatTimeString(item.time.toIso8601String());

          return HourCard(
            timeLabel,
            item.icon,
            '${item.temperature.round()}°',
            active: isFirst,
          );
        }),
      ),
    );
  }

  Widget _buildDailyForecast(WeatherData weather) {
    if (weather.daily.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(weather.daily.length, (index) {
        final item = weather.daily[index];
        return ForecastCard(
          forecast: item,
          isToday: index == 0,
        );
      }),
    );
  }

  Widget _buildWeatherDetails(WeatherData weather) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth > 750 ? 3 : 2;
        final cardWidth = (box.maxWidth - (columns - 1) * 14) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'Humidity',
                '${weather.relativeHumidity}%',
                _getHumiditySubtitle(weather.relativeHumidity),
                Icons.water_drop,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'Wind Speed',
                '${weather.windSpeed.toStringAsFixed(1)} km/h',
                _getWindSubtitle(weather.windSpeed),
                Icons.air,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'Feels Like',
                '${weather.apparentTemperature.round()}°C',
                _getFeelsLikeSubtitle(
                  weather.temperature,
                  weather.apparentTemperature,
                ),
                Icons.thermostat,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'UV Index',
                weather.uvIndex.toStringAsFixed(1),
                _getUvSubtitle(weather.uvIndex),
                Icons.wb_sunny,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'Visibility',
                '${weather.visibilityKm.toStringAsFixed(1)} km',
                _getVisibilitySubtitle(weather.visibilityKm),
                Icons.visibility,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DetailCard(
                'Pressure',
                '${weather.surfacePressure.round()} hPa',
                _getPressureSubtitle(weather.surfacePressure),
                Icons.speed,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSunriseSunset(WeatherData weather) {
    return Row(
      children: [
        Expanded(
          child: SunCard(
            'Sunrise',
            weather.sunrise,
            Icons.wb_twilight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SunCard(
            'Sunset',
            weather.sunset,
            Icons.nights_stay,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }
}

