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
<<<<<<< HEAD
      case 'S':
        return const Color(0xFF7E57C2); // Purple
      case 'A':
        return const Color(0xFF66BB6A); // Green
      case 'B':
        return const Color(0xFF42A5F5); // Blue
      case 'C':
        return const Color(0xFFFFD54F); // Yellow
      case 'D':
        return const Color(0xFFFF9800); // Orange
      case 'F':
        return const Color(0xFFEF5350); // Red
      default:
        return Colors.grey;
=======
      case 'S': return Colors.purple;
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.yellow;
      case 'D': return Colors.orange;
      case 'F': return Colors.red;
      default: return Colors.grey;
>>>>>>> bce5103559db56301f31948ef14741626a5e8df3
    }
  }

  String formatMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

<<<<<<< HEAD
  int get weeklyAverage {
    int total = lastWeekScreentime.fold(0, (sum, val) => sum + val);
    return total > 0 ? ((total - userScreentime) / max(1, min(6, lastWeekScreentime.where((t) => t > 0).length - 1))).round() : 0;
  }

  int loop6(int i) {
    if (i > 6) return i - 7;
    return i;
=======
  // Improved circular indexing
  int circularIndex(int index) {
    return (index + _day) % 7;
>>>>>>> bce5103559db56301f31948ef14741626a5e8df3
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 32,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black54),
              onPressed: _shareScreenshot,
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _rankFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Failed to load leaderboard data',
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
              );
            } else {
              final data = snapshot.data!;
              final tier = data['tier'];
              final userScreentime = data['userScreentime'];
              final globalAverage = data['globalAverage'];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // My Rank section
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 8, bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.expand_more, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'My Rank',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
<<<<<<< HEAD
                          ],
=======
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
>>>>>>> bce5103559db56301f31948ef14741626a5e8df3
                        ),
                      ),
                      
                      // Rank card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: getRankColor(tier),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        tier,
                                        style: TextStyle(
                                          color: getRankColor(tier),
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Rank',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        getRankTitle(tier),
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Screen time indicator
                                  Container(
                                    width: double.infinity,
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final barWidth = constraints.maxWidth - 16;
                                        final userPercentage = userScreentime / 1440;
                                        final weeklyPercentage = weeklyAverage / 1440;
                                        final globalPercentage = globalAverage / 1440;
                                        
                                        return Stack(
                                          children: [
                                            // Progress bar
                                            Positioned(
                                              top: 8,
                                              left: 0,
                                              child: Container(
                                                width: userPercentage * barWidth,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: getRankColor(tier).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: getRankColor(tier),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            // Weekly average marker
                                            if (weeklyAverage > 0)
                                              Positioned(
                                                top: 8,
                                                left: weeklyPercentage * barWidth - 1,
                                                child: Container(
                                                  width: 2,
                                                  height: 24,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            
                                            // Global average marker
                                            Positioned(
                                              top: 8,
                                              left: globalPercentage * barWidth - 1,
                                              child: Container(
                                                width: 2,
                                                height: 24,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        '0h',
                                        style: TextStyle(color: Colors.black54, fontSize: 12),
                                      ),
                                      Text(
                                        '24h',
                                        style: TextStyle(color: Colors.black54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Stats row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatPill(
                                          'Your Screentime', 
                                          formatMinutes(userScreentime),
                                          Colors.grey.shade100,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatPill(
                                          'Weekly Average', 
                                          formatMinutes(weeklyAverage),
                                          Colors.grey.shade100,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  _buildStatPill(
                                    'Global Average', 
                                    formatMinutes(globalAverage),
                                    Colors.grey.shade100,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Weekly activity section
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 16),
                        child: Row(
                          children: [
                            Icon(Icons.expand_more, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Weekly Activity',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Weekly chart card
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last 7 Days',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: _buildBarChart(globalAverage, weeklyAverage),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
  
  String getRankTitle(String tier) {
    switch (tier) {
      case 'S':
        return 'Digital Minimalist';
      case 'A':
        return 'Balanced User';
      case 'B':
        return 'Average User';
      case 'C':
        return 'Heavy User';
      case 'D':
        return 'Very Heavy User';
      case 'F':
        return 'Digital Addict';
      default:
        return 'Unknown';
    }
  }
  
  Widget _buildStatPill(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBarChart(int globalAverage, int weeklyAverage) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 840, // 14 hours is a reasonable max for most users
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 120,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 120,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        barGroups: List.generate(7, (index) {
          final value = lastWeekScreentime[index].toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: index == 6 ? Colors.blue : Colors.grey.shade300,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 840,
                  color: Colors.grey.shade100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}