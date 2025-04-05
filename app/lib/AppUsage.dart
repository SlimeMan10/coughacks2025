import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For platform channel
import 'Permissions.dart'; // Import the new file

class AppUsageApp extends StatefulWidget {
  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> {
  List<AppUsageInfo> _infos = [];
  Map<String, AppInfo> _appMap = {};
  bool _isLoading = false;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();

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

      // Fetch usage stats
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        _startDate,
        _endDate,
      );

      // Fetch installed apps
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
        _error = "Failed to load data.\nEnsure permissions are granted.";
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

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString =
        "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              Text(
                "Usage for: $timeRangeString",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).appBarTheme.foregroundColor
                          ?.withOpacity(0.8) ??
                      Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
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
                    : ListView.builder(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getUsageStatsAndIcons,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
