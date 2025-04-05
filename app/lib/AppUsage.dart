import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For platform channel

// Helper function to format Duration
String formatDuration(Duration duration) {
  if (duration.inSeconds < 1) return "< 1s";
  if (duration.inMinutes < 1) return "${duration.inSeconds}s";
  if (duration.inHours < 1) return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

// Platform channel to fetch permissions
const platform = MethodChannel('com.example.app/permissions');

Future<List<String>> getAppPermissions(String packageName) async {
  try {
    final List<dynamic> permissions = await platform.invokeMethod('getPermissions', {'packageName': packageName});
    return permissions.cast<String>();
  } catch (e) {
    print("Error fetching permissions for $packageName: $e");
    return [];
  }
}

class AppUsageApp extends StatefulWidget {
  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> with SingleTickerProviderStateMixin {
  List<AppUsageInfo> _infos = [];
  Map<String, AppInfo> _appMap = {};
  Map<String, List<String>> _permissionsMap = {}; // Store permissions
  bool _isLoading = false;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(_startDate, _endDate);

      // Fetch installed apps
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true, "");
      _appMap = {for (var app in installedApps) app.packageName: app};

      // Fetch permissions for each app
      for (var app in installedApps) {
        _permissionsMap[app.packageName] = await getAppPermissions(app.packageName);
      }

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

  // Privacy risk flags
  List<String> _privacyRisks = [
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.READ_PHONE_STATE',
  ];

  Widget _buildUsageTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }
    if (_infos.isEmpty) return const Center(child: Text('No usage data found.\n(Or permissions needed)', textAlign: TextAlign.center));

    return ListView.builder(
      itemCount: _infos.length,
      itemBuilder: (context, index) {
        final info = _infos[index];
        final app = _appMap[info.packageName];
        Widget appIcon = Icon(Icons.android, size: 40, color: Theme.of(context).colorScheme.primary);
        if (app != null && app.icon != null) {
          appIcon = Image.memory(app.icon!, width: 40, height: 40);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 2.0,
          child: ListTile(
            leading: appIcon,
            title: Text(info.appName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            trailing: Text(formatDuration(info.usage), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildPermissionsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_permissionsMap.isEmpty) return const Center(child: Text('No permission data available.', textAlign: TextAlign.center));


    void onPressed() {
      print("button");
    }


    return Column(
      children: [ElevatedButton(onPressed: onPressed, child: Text("Show")),
        Expanded(
        child: ListView.builder(
          itemCount: _appMap.length,
          itemBuilder: (context, index) {
            final app = _appMap.values.elementAt(index);
            final permissions = _permissionsMap[app.packageName] ?? [];
            final hasRisks = permissions.any((p) => _privacyRisks.contains(p));
        
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              elevation: 2.0,
              color: hasRisks ? Colors.orange[50] : null, // Highlight risky apps
              child: ExpansionTile(
                leading: app.icon != null ? Image.memory(app.icon!, width: 40, height: 40) : const Icon(Icons.android, size: 40),
                title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(hasRisks ? 'Potential Privacy Risks' : 'No major risks detected', style: TextStyle(color: hasRisks ? Colors.red : Colors.green)),
                children: permissions.map((perm) {
                  final isRisky = _privacyRisks.contains(perm);
                  return ListTile(
                    title: Text(perm, style: TextStyle(color: isRisky ? Colors.red : null)),
                    dense: true,
                  );
                }).toList(),
              ),
            );
          },
        ),
      )],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString = "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage & Privacy'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68.0),
          child: Column(
            children: [
              Text(
                "Usage for: $timeRangeString",
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.8) ?? Colors.white70,
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Usage Stats'),
                  Tab(text: 'Permissions'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUsageTab(),
            _buildPermissionsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getUsageStatsAndIcons,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Time Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent),
        appBarTheme: const AppBarTheme(elevation: 1.0),
        cardTheme: CardTheme(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
      home: AppUsageApp(),
    );
  }
}

void main() {
  runApp(MyApp());
}