import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() {
  runApp(const MaterialApp(
    home: AppUsageApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class AppUsageApp extends StatefulWidget {
  const AppUsageApp({super.key});

  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> with AutomaticKeepAliveClientMixin {
  List<AppUsageInfo> _infos = [];
  Map<String, AppInfo> _appMap = {};
  bool _isLoading = false;
  String? _error;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();

  RangeValues _dateRange = const RangeValues(6, 7);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateDateRange(_dateRange);
  }

  void _updateDateRange(RangeValues range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(Duration(days: (7 - range.start).floor()));
    final end = todayStart.subtract(Duration(days: (7 - range.end).floor()));
    _startDate = DateTime(start.year, start.month, start.day, 3);
    _endDate = DateTime(end.year, end.month, end.day, now.hour, now.minute, now.second);
    getUsageStatsAndIcons();
  }

  Future<void> getUsageStatsAndIcons() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(_startDate, _endDate);
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true, "");
      _appMap = {for (var app in installedApps) app.packageName: app};

      infoList.removeWhere((info) => info.usage.inSeconds <= 0);
      infoList.sort((a, b) => b.usage.compareTo(a.usage));

      setState(() {
        _infos = infoList;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load data.\nEnsure usage access permissions are granted.";
        _infos = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String formatDuration(Duration duration) {
    if (duration.inSeconds < 1) return "< 1s";
    String result = "${duration.inSeconds.remainder(60)}s";
    if (duration.inMinutes >= 1) result = "${duration.inMinutes.remainder(60)}m $result";
    if (duration.inHours >= 1) result = "${duration.inHours.remainder(60)}h $result";
    if (duration.inDays >= 1) result = "${duration.inDays.remainder(60)}d $result";
    return result;
  }

  String inferCategory(String packageName) {
    packageName = packageName.toLowerCase();
    if (packageName.contains('youtube') || packageName.contains('netflix') || packageName.contains('video') || packageName.contains('music')) {
      return 'Entertainment';
    } else if (packageName.contains('facebook') || packageName.contains('twitter') || packageName.contains('instagram') || packageName.contains('social')) {
      return 'Social';
    } else if (packageName.contains('chrome') || packageName.contains('docs') || packageName.contains('office') || packageName.contains('email')) {
      return 'Productivity';
    } else if (packageName.contains('game') || (packageName.contains('play') && !packageName.contains('google'))) {
      return 'Games';
    } else if (packageName.contains('messenger') || packageName.contains('whatsapp') || packageName.contains('chat')) {
      return 'Communication';
    } else {
      return 'Other';
    }
  }

  Duration getTotalUsage() {
    return _infos.fold(Duration.zero, (sum, info) => sum + info.usage);
  }

  Map<String, Duration> getCategoryBreakdown() {
    Map<String, Duration> breakdown = {};
    for (var info in _infos) {
      String category = inferCategory(info.packageName);
      breakdown[category] = (breakdown[category] ?? Duration.zero) + info.usage;
    }
    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString = "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            expandedHeight: 330.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(''),
              background: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildInsightsHeader(timeRangeString),
                    _buildDateRangeSlider(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _infos.isEmpty
                          ? const Center(
                              child: Text(
                                'No usage data found.\n(Or permissions needed)',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'App Usage',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                ..._infos.map((info) {
                                  final app = _appMap[info.packageName];
                                  Widget appIcon = Icon(Icons.android, size: 36, color: Colors.white70);
                                  if (app != null && app.icon != null) {
                                    appIcon = Image.memory(app.icon!, width: 36, height: 36);
                                  }

                                  double usagePercent = info.usage.inSeconds / getTotalUsage().inSeconds;

                                  return Stack(
                                    children: [
                                      Container(
                                        height: 70,
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.blueAccent.withOpacity(0.1),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: usagePercent.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        leading: appIcon,
                                        title: Text(info.appName, style: const TextStyle(color: Colors.white)),
                                        subtitle: Text(
                                          inferCategory(info.packageName),
                                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                                        ),
                                        trailing: Text(
                                          formatDuration(info.usage),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        onPressed: () => _updateDateRange(_dateRange),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildInsightsHeader(String timeRangeString) {
    final totalUsage = getTotalUsage();
    final categoryBreakdown = getCategoryBreakdown();
    final double usagePercentage = totalUsage.inMinutes / (24 * 60);

    return Column(
      children: [
        const SizedBox(height: 16),
        CircularPercentIndicator(
          radius: 58.0,
          lineWidth: 8.0,
          percent: usagePercentage > 1 ? 1 : usagePercentage,
          center: Text(
            formatDuration(totalUsage),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          progressColor: Colors.blueAccent,
          backgroundColor: Colors.white12,
        ),
        const SizedBox(height: 12),
        Text(
          "Total Screen Time",
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
        ),
        Text(
          timeRangeString,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
        ),
        const SizedBox(height: 10),
        _buildCategorySummary(categoryBreakdown),
      ],
    );
  }

  Widget _buildCategorySummary(Map<String, Duration> breakdown) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: breakdown.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${entry.key}: ${formatDuration(entry.value)}",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('Select Date Range (Last 7 days)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          RangeSlider(
            min: 0,
            max: 7,
            divisions: 7,
            values: _dateRange,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white24,
            labels: RangeLabels(
              "${7 - _dateRange.start.toInt()}d ago",
              _dateRange.end.toInt() == 7 ? "Now" : "${7 - _dateRange.end.toInt()}d ago",
            ),
            onChanged: (values) {
              if ((values.end - values.start) <= 7) {
                setState(() => _dateRange = values);
              }
            },
            onChangeEnd: (values) => _updateDateRange(values),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
