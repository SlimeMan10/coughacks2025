import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:app_usage/app_usage.dart';

// Placeholder for missing imports
import 'ScreenTimePieChart.dart';
import 'shareScreenshot.dart';

class LocalLeaderboard extends StatefulWidget {
  const LocalLeaderboard({super.key});

  @override
  State<LocalLeaderboard> createState() => _LocalLeaderboardState();
}

class _LocalLeaderboardState extends State<LocalLeaderboard> {
  late Future<Map<String, dynamic>> _rankFuture;
  final ScreenshotController _screenshotController = ScreenshotController();

  void _shareScreenshot() {
    ShareScreenshot(
      context: context,
      screenshotController: _screenshotController,
    ).captureAndShare();
  }

  List<int> lastWeekScreentime = List.filled(7, 0);
  int userScreentime = 0;

  Future<void> getScreentimeLast7Days() async {
    final AppUsage appUsage = AppUsage();
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    for (int i = 6; i >= 0; i--) {
      DateTime startOfDay = todayMidnight.subtract(Duration(days: i));
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      try {
        List<AppUsageInfo> usage = await appUsage.getAppUsage(startOfDay, endOfDay);

        Duration totalScreentime = usage.fold(
          Duration.zero, 
          (total, info) => total + info.usage
        );

        lastWeekScreentime[6-i] = totalScreentime.inMinutes;
      } catch (e) {
        print('Error getting usage for $startOfDay - $endOfDay: $e');
        lastWeekScreentime[6-i] = 0;
      }
    }
    
    // Update user screentime to today's screentime
    userScreentime = lastWeekScreentime[6];
  }

  final List<String> weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  final _day = (DateTime.now().weekday + 6) % 7;

  @override
  void initState() {
    super.initState();
    _rankFuture = _initData();
  }

  Future<Map<String, dynamic>> _initData() async {
    await getScreentimeLast7Days();
    return calculateRank();
  }

  Future<Map<String, dynamic>> calculateRank() async {
    int globalAverage = 400; // Example global average

    String tier = getRankTier(userScreentime, weeklyAverage);
    return {
      'userScreentime': userScreentime,
      'globalAverage': globalAverage,
      'tier': tier,
    };
  }

  // Improved weekly average calculation
  int get weeklyAverage {
    if (lastWeekScreentime.length < 7) return 0;
    
    int total = lastWeekScreentime.take(6).fold(0, (sum, val) => sum + val);
    return (total / 6).round();
  }

  String getNextLowerRank(String currentRank) {
    const ranks = ['S', 'A', 'B', 'C', 'D', 'F'];
    final index = ranks.indexOf(currentRank);
    return (index == -1 || index == ranks.length - 1) 
      ? currentRank 
      : ranks[index + 1];
  }

  String getRankTier(int userTime, int avg) {
    if (avg == 0) return 'B'; // Default case to prevent division by zero
    
    double ratio = userTime / avg;
    if (ratio >= 2.0) return 'F';
    if (ratio >= 1.5) return 'D';
    if (ratio >= 1.2) return 'C';
    if (ratio >= 0.9) return 'B';
    if (ratio >= 0.6) return 'A';
    return 'S';
  }

  int getTimeToDerank(int userTime, int avg) {
    String currentRank = getRankTier(userTime, avg);
    String nextRank = getNextLowerRank(currentRank);

    Map<String, double> rankThresholds = {
      'S': 0.6,
      'A': 0.9,
      'B': 1.2,
      'C': 1.5,
      'D': 2.0,
      'F': 2.0, // no derank possible
    };

    double nextThreshold = rankThresholds[nextRank]!;
    return (avg * nextThreshold).ceil();
  }

  Color getRankColor(String tier) {
    switch (tier) {
      case 'S': return Colors.purple;
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.yellow;
      case 'D': return Colors.orange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }

  String formatMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  // Improved circular indexing
  int circularIndex(int index) {
    return (index + _day) % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: const Color(0xFF101010),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Local Leaderboard',
            style: TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _rankFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final data = snapshot.data!;
              final tier = data['tier'];
              final userScreentime = data['userScreentime'];
              final globalAverage = data['globalAverage'];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: getRankColor(tier),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                tier,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 40,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final barWidth = constraints.maxWidth;
                                      final userPosition = (userScreentime / 1440) * barWidth;
                                      final globalPosition = (globalAverage / 1440) * barWidth;
                                      final weeklyPosition = (weeklyAverage / 1440) * barWidth;

                                      return Stack(
                                        children: [
                                          Positioned(
                                            top: 14,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.white12,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 14,
                                            left: 0,
                                            child: Container(
                                              width: userPosition > 0 ? userPosition : 0,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: getRankColor(tier),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 14,
                                            left: globalPosition > 0 ? globalPosition : 0,
                                            child: Container(
                                              width: 3,
                                              height: 24,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Positioned(
                                            top: 14,
                                            left: weeklyPosition > 0 ? weeklyPosition : 0,
                                            child: Container(
                                              width: 3,
                                              height: 24,
                                              color: const Color.fromARGB(255, 126, 126, 126),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text(
                                      '0',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      '24h',
                                      style: TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Screentime Today: ${formatMinutes(userScreentime)}',
                        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                      ),
                      Text(
                        'Weekly Average: ${formatMinutes(weeklyAverage)}',
                        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                      ),
                      Text(
                        'Global Average: ${formatMinutes(globalAverage)}',
                        style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Last 7 Days',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1.7,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 1440,
                            minY: 0,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${weekdays[circularIndex(group.x)]}: ${formatMinutes(rod.toY.toInt())}',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        weekdays[circularIndex(value.toInt())],
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int hours = value ~/ 60;
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        '${hours}h',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    );
                                  },
                                  reservedSize: 40,
                                  interval: 120,
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 60,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(color: Colors.white10, strokeWidth: 1);
                              },
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: weeklyAverage.toDouble(),
                                  color: Colors.amberAccent,
                                  strokeWidth: 1.5,
                                  dashArray: [4, 2],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (_) => 'Weekly Avg',
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                HorizontalLine(
                                  y: globalAverage.toDouble(),
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  strokeWidth: 1.5,
                                  dashArray: [4, 2],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (_) => 'Global Avg',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              ),
                            barGroups: _buildBarGroups(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: buildScreentimePieChart(
                          weeklyAverage: weeklyAverage,
                          userAverage: userScreentime,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white12,
          foregroundColor: Colors.white,
          onPressed: _shareScreenshot,
          child: const Icon(Icons.share),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: lastWeekScreentime[index].toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}