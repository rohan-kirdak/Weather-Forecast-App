# Weatherly – Professional Weather Forecast App

Weatherly is a modern, responsive, and feature-complete Weather Forecast application built with Flutter and Material Design 3. It fetches real-time meteorological data and location coordinates using Open-Meteo's free REST APIs without requiring API keys.

---

## 🌟 Features

- **Real-Time Weather Data**:
  - Live temperature with animated weather condition icons.
  - Feels-like temperature.
  - Humidity percentage with qualitative comfort index.
  - Wind speed in km/h with Beaufort-scale descriptions.
  - Atmospheric surface pressure in hPa.
  - Visibility distance in kilometers.
  - UV Index rating (Low, Moderate, High, Extreme).
  - High and Low temperatures for today.

- **Worldwide City Search**:
  - Global city search powered by the Open-Meteo Geocoding API.
  - Debounced dynamic search suggestions.
  - Quick-reset button to default city (Pune, India).
  - Search error handling for invalid or unavailable locations.

- **Hourly Forecast**:
  - 24-hour horizontal scrollable weather timeline.
  - Hourly temperature, weather icons, and condition states.
  - "Now" highlight card for the current hour.

- **7-Day Daily Forecast**:
  - 7-day extended forecast with day names and calendar dates.
  - Daily weather condition description and weather icons.
  - Maximum and minimum temperature range.

- **Astronomical Data**:
  - Local sunrise and sunset timings automatically formatted for the target city's timezone.

- **UI & UX Design**:
  - Dark navy & deep blue gradient theme (`#101D40`, `#102F59`, `#07152D`).
  - Frosted glassmorphism card styling with subtle borders and shadows.
  - Fully responsive layout adapting smoothly from mobile screens to desktop browsers.
  - Pull-to-refresh support and manual retry upon network failure.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (v3.47+)
- **Language**: [Dart](https://dart.dev) (v3.13+)
- **Design System**: Material Design 3
- **Networking**: `http: ^1.6.0`
- **APIs**:
  - **Weather Data**: [Open-Meteo Weather Forecast API](https://open-meteo.com/en/docs)
  - **Geocoding**: [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api)

---

## 🌐 API Endpoints Used

### 1. Open-Meteo Geocoding API
Searches worldwide cities by name to retrieve latitude, longitude, country, and admin region:
```http
GET https://geocoding-api.open-meteo.com/v1/search?name={city}&count=6&language=en&format=json
```

### 2. Open-Meteo Forecast API
Retrieves current weather, hourly forecast, 7-day daily forecast, and sunrise/sunset times in the city's local timezone:
```http
GET https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,surface_pressure,wind_speed_10m,is_day&hourly=temperature_2m,weather_code,visibility,uv_index&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max&timezone=auto
```

---

## 📁 Project Structure

```text
weather_app/
├── lib/
│   ├── main.dart                      # App entry point, theme & system overlay config
│   ├── models/
│   │   └── weather_model.dart         # WeatherData, HourlyForecast, DailyForecast, CityLocation
│   ├── screens/
│   │   └── weather_screen.dart        # Main responsive weather dashboard & search controller
│   ├── services/
│   │   └── weather_service.dart       # Open-Meteo REST API client & error handling
│   └── widgets/
│       ├── detail_card.dart           # Metric cards (Humidity, Wind, UV, Pressure, etc.)
│       ├── forecast_card.dart         # 7-day forecast row card
│       ├── hour_card.dart             # Hourly forecast horizontal card
│       └── sun_card.dart              # Sunrise and sunset card
├── test/
│   ├── weather_service_test.dart      # Integration tests for live Open-Meteo API & models
│   └── weather_screen_test.dart       # Widget tests for loading, error, and success states
├── pubspec.yaml                       # Dependencies and asset configuration
└── README.md                          # Documentation
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Google Chrome browser (for web testing) or an Android device/emulator

### Installation & Run

1. Clone or navigate into the project directory:
   ```bash
   cd weather_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run static analysis:
   ```bash
   flutter analyze
   ```

4. Run the automated test suite:
   ```bash
   flutter test
   ```

5. Run on Google Chrome:
   ```bash
   flutter run -d chrome
   ```

6. Run on Android:
   ```bash
   flutter run -d <android-device-id>
   ```

---

## 🧪 Testing Verification

The app includes automated unit, integration, and widget tests:
- **API integration**: Verifies live geocoding search and live forecast retrieval from Open-Meteo.
- **Model parsing**: Verifies WMO code mapping to readable descriptions and Material icons.
- **Widget states**: Verifies loading indicator, error handling with a retry button, and full dashboard rendering.

---

## 🔮 Future Improvements

- Offline caching using `shared_preferences` or `hive`.
- Animated weather backgrounds matching current precipitation/sun conditions.
- Multi-language support (English, Marathi, Hindi).
