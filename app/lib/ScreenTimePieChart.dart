import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ScreenTimePieChart extends StatelessWidget {
  final int userAverage;
  final int weeklyAverage;

  const ScreenTimePieChart({
    Key? key,
    required this.userAverage,
    required this.weeklyAverage,
  }) : super(key: key);

  String getRankTier(int userTime, int avg) {
    double ratio = userTime / avg;
    if (ratio >= 2.0) return 'F';
    if (ratio >= 1.5) return 'D';
    if (ratio >= 1.2) return 'C';
    if (ratio >= 0.9) return 'B';
    if (ratio >= 0.6) return 'A';
    return 'S';
  }

  String getNextRank(String current) {
    const List<String> tiers = ['S', 'A', 'B', 'C', 'D', 'F'];
    final currentIndex = tiers.indexOf(current);
    if (currentIndex < 0 || currentIndex == tiers.length - 1) return '-';
    return tiers[currentIndex + 1];
  }

  int getThresholdForNextRank(String nextRank) {
    const Map<String, double> thresholds = {
      'S': 0.2,
      'A': 0.6,
      'B': 0.9,
      'C': 1.2,
      'D': 1.5,
      'F': 2.0,
    };
    return (weeklyAverage * (thresholds[nextRank] ?? 2.0)).floor();
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = getRankTier(userAverage, weeklyAverage);

    if (currentTier == 'F') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text(
            'You already have an F today! Work on doing better next time!',
            style: TextStyle(
              fontSize: 22,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            width: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: 1,
                        color: Colors.redAccent,
                        radius: 40,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                const Text(
                  '100%',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    // ... (original non-F logic continues here)
    final nextTier = getNextRank(currentTier);
    final nextTierThreshold = getThresholdForNextRank(nextTier);
    final timeLeft = (nextTierThreshold - userAverage).clamp(
      0,
      nextTierThreshold,
    );
    final double progress = (userAverage / nextTierThreshold).clamp(0.0, 1.0);

    Color fillColor;
    if (progress < 0.5) {
      fillColor = Colors.greenAccent;
    } else if (progress < 0.8) {
      fillColor = Colors.orangeAccent;
    } else {
      fillColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text(
          '$timeLeft minutes left until rank drops to $nextTier!',
          style: TextStyle(
            fontSize: 22,
            color: fillColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 50,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: userAverage.toDouble(),
                      color: fillColor,
                      radius: 40,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: (nextTierThreshold - userAverage).toDouble(),
                      color: Colors.grey.withOpacity(0.2),
                      radius: 40,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Widget buildScreentimePieChart({
  required int weeklyAverage,
  required int userAverage,
}) {
  return ScreenTimePieChart(
    weeklyAverage: weeklyAverage,
    userAverage: userAverage,
  );
}
