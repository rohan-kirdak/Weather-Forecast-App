import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class ForecastCard extends StatelessWidget {
  final DailyForecast forecast;
  final bool isToday;

  const ForecastCard({
    required this.forecast,
    this.isToday = false,
    super.key,
  });

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDayTitle(DateTime date) {
    if (isToday) return 'Today';
    return _weekdays[date.weekday - 1];
  }

  String _formatDateSubtitle(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF4776B4).withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isToday ? 0.30 : 0.08),
        ),
      ),
      child: Row(
        children: [
          // Day and Date
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDayTitle(forecast.date),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateSubtitle(forecast.date),
                  style: const TextStyle(
                    color: Color(0xFFB4C5DE),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Weather Icon and Condition
          Expanded(
            child: Row(
              children: [
                Icon(
                  forecast.icon,
                  color: const Color(0xFFFFC66D),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    forecast.condition,
                    style: const TextStyle(
                      color: Color(0xFFB4C5DE),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // High / Low temperatures
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${forecast.maxTemperature.round()}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' / ',
                style: TextStyle(
                  color: Color(0xFFB4C5DE),
                  fontSize: 14,
                ),
              ),
              Text(
                '${forecast.minTemperature.round()}°',
                style: const TextStyle(
                  color: Color(0xFFB4C5DE),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

