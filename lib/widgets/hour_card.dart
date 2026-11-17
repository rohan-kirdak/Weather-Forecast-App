import 'package:flutter/material.dart';

class HourCard extends StatelessWidget {
  final String time;
  final IconData icon;
  final String temperature;
  final bool active;

  const HourCard(
    this.time,
    this.icon,
    this.temperature, {
    this.active = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF4776B4)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: active ? 0.35 : 0.10),
        ),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 15),
          Icon(icon, color: const Color(0xFFFFC66D), size: 28),
          const SizedBox(height: 15),
          Text(
            temperature,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

