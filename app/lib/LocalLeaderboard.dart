import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'ScreenTimePieChart.dart';
import 'shareScreenshot.dart';
import 'package:screenshot/screenshot.dart';

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


  // Simulated data for the last 7 days
  List<int> lastWeekScreentime = List.generate(7, (_) => Random().nextInt(600));
  // Day labels for the chart
  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _rankFuture = calculateRank();
  }

  Future<Map<String, dynamic>> calculateRank() async {
    // Replace this with actual screentime retrieval logic
    int userScreentime = Random().nextInt(
      600,
    ); // Simulated user screentime in minutes
    int globalAverage = 400; // Example global average

    String tier = getRankTier(userScreentime, weeklyAverage);
    return {
      'userScreentime': userScreentime,
      'globalAverage': globalAverage,
      'tier': tier,
    };
  }

  String getNextLowerRank(String currentRank) {
    const ranks = ['S', 'A', 'B', 'C', 'D', 'F'];
    final index = ranks.indexOf(currentRank);
    if (index == -1 || index == ranks.length - 1)
      return currentRank; // Already F or invalid
    return ranks[index + 1];
  }

  String getRankTier(int userTime, int avg) {
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
      'F': double.infinity, // no derank possible
    };

    double nextThreshold = rankThresholds[nextRank]!;
    return (avg * nextThreshold).ceil();
  }

  Color getRankColor(String tier) {
    switch (tier) {
      case 'S':
        return Colors.purple;
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.yellow;
      case 'D':
        return Colors.orange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void refreshLeaderboard() {
    setState(() {
      _rankFuture = calculateRank();
    });
  }

  String formatMinutes(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  int get weeklyAverage {
    int total = lastWeekScreentime.fold(0, (sum, val) => sum + val);
    return (total / lastWeekScreentime.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    // Rank bar visualization
                    Row(
                      children: [
                        // Rank letter on the left
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
                        // Progress bar showing screentime out of 1440 minutes
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height:
                                    40, // Increased height to accommodate labels
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final barWidth = constraints.maxWidth;
                                    final userPosition =
                                        (userScreentime / 1440) * barWidth;
                                    final globalPosition =
                                        (globalAverage / 1440) * barWidth;
                                    final weeklyPosition =
                                        (weeklyAverage / 1440) * barWidth;

                                    return Stack(
                                      children: [
                                        // Background bar (full day) - Positioned in the middle
                                        Positioned(
                                          top: 14, // Center the bar vertically
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        // User's screentime - Positioned in the middle
                                        Positioned(
                                          top: 14, // Center the bar vertically
                                          left: 0,
                                          child: Container(
                                            width:
                                                userPosition > 0
                                                    ? userPosition
                                                    : 0,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: getRankColor(tier),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        // Global average marker - Positioned in the middle
                                        Positioned(
                                          top: 14, // Center the bar vertically
                                          left:
                                              globalPosition > 0
                                                  ? globalPosition
                                                  : 0,
                                          child: Container(
                                            width: 3,
                                            height: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        // WeeklyAverage
                                        Positioned(
                                          top: 14, // Center the bar vertically
                                          left:
                                              weeklyPosition > 0
                                                  ? weeklyPosition
                                                  : 0,
                                          child: Container(
                                            width: 3,
                                            height: 24,
                                            color: const Color.fromARGB(
                                              255,
                                              126,
                                              126,
                                              126,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '24h',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
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
                      'Your Screentime: ${formatMinutes(userScreentime)}',
                      style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                    ),
                    Text(
                      'Weekly Average: ${formatMinutes(weeklyAverage)}',
                      style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 16),
                    ),
                    Text(
                      'Global Average: ${formatMinutes(globalAverage)}',
                      style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 16),
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
                          maxY: 600,
                          minY: 0,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                return BarTooltipItem(
                                  '${weekdays[group.x.toInt()]}: ${formatMinutes(rod.toY.toInt())}',
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
                                      weekdays[value.toInt()],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
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
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 40,
                                interval: 120,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 120,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white10,
                                strokeWidth: 1,
                              );
                            },
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),

                          // Weekly average line
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
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bar data (no global bar)
                          barGroups: _buildBarGroups(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Added proper widget to display the pie chart
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
