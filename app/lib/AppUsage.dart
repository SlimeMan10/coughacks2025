import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart'; // Add to pubspec.yaml

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getUsageStatsAndIcons();
  }

  Future<void> getUsageStatsAndIcons() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(const Duration(days: 1));

      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        _startDate,
        _endDate,
      );

      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        false,
        true,
        "",
      );
      _appMap = {for (var app in installedApps) app.packageName: app};

      infoList.removeWhere((info) => info.usage.inSeconds <= 0);
      infoList.sort((a, b) => b.usage.compareTo(a.usage));

      setState(() {
        _infos = infoList;
        _isLoading = false;
      });
    } catch (exception) {
      print("Error fetching data: $exception");
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
    if (duration.inMinutes < 1) return "${duration.inSeconds}s";
    if (duration.inHours < 1)
      return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Dynamic category inference based on package name
  String inferCategory(String packageName) {
    packageName = packageName.toLowerCase();
    if (packageName.contains('youtube') || 
        packageName.contains('netflix') || 
        packageName.contains('video') ||
        packageName.contains('music')) {
      return 'Entertainment';
    } else if (packageName.contains('facebook') || 
               packageName.contains('twitter') || 
               packageName.contains('instagram') ||
               packageName.contains('social')) {
      return 'Social';
    } else if (packageName.contains('chrome') || 
               packageName.contains('docs') || 
               packageName.contains('office') ||
               packageName.contains('email')) {
      return 'Productivity';
    } else if (packageName.contains('game') || 
               packageName.contains('play') && !packageName.contains('google')) {
      return 'Games';
    } else if (packageName.contains('messenger') || 
               packageName.contains('whatsapp') || 
               packageName.contains('chat')) {
      return 'Communication';
    } else {
      return 'Other';
    }
  }

  // Calculate total usage time
  Duration getTotalUsage() {
    return _infos.fold(Duration.zero, (sum, info) => sum + info.usage);
  }

  // Calculate category breakdown dynamically
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
    final String timeRangeString =
        "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Screen Time Insights'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: _buildInsightsHeader(timeRangeString),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _infos.isEmpty
                          ? const Center(
                              child: Text(
                                'No usage data found.\n(Or permissions needed)',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'App Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _infos.length,
                                  itemBuilder: (context, index) {
                                    final info = _infos[index];
                                    final app = _appMap[info.packageName];
                                    Widget appIcon = Icon(
                                      Icons.android,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    );
                                    if (app != null && app.icon != null) {
                                      appIcon = Image.memory(app.icon!, width: 40, height: 40);
                                    }

                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      elevation: 2.0,
                                      child: ListTile(
                                        leading: appIcon,
                                        title: Text(
                                          info.appName,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          inferCategory(info.packageName),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: Text(
                                          formatDuration(info.usage),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getUsageStatsAndIcons,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildInsightsHeader(String timeRangeString) {
    final totalUsage = getTotalUsage();
    final categoryBreakdown = getCategoryBreakdown();
    final double usagePercentage = totalUsage.inMinutes / (24 * 60); // Percentage of day

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 10.0,
            percent: usagePercentage > 1 ? 1 : usagePercentage,
            center: Text(
              formatDuration(totalUsage),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            progressColor: Colors.white,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            "Total Screen Time",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            timeRangeString,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategorySummary(categoryBreakdown),
        ],
      ),
    );
  }

  Widget _buildCategorySummary(Map<String, Duration> breakdown) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: breakdown.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${entry.key}: ${formatDuration(entry.value)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}