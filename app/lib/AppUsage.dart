import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:intl/intl.dart'; // For date formatting if needed later

// Helper function to format Duration into a user-friendly string
String formatDuration(Duration duration) {
  if (duration.inSeconds < 1) {
    return "< 1s";
  }
  if (duration.inMinutes < 1) {
    return "${duration.inSeconds}s";
  }
  if (duration.inHours < 1) {
    return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
  }
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

class AppUsageApp extends StatefulWidget {
  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> {
  List<AppUsageInfo> _infos = [];
  bool _isLoading = false;
  String? _error;

  // Define the time range for fetching stats
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Load usage stats when the widget is first created
    getUsageStats();
  }

  Future<void> getUsageStats() async {
    // Don't fetch if already loading
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null; // Clear previous errors
    });

    try {
      // Update end date to now, and start date relative to it
      _endDate = DateTime.now();
      _startDate = _endDate.subtract(
        const Duration(days: 1),
      ); // Example: Last 24 hours

      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        _startDate,
        _endDate,
      );

      // Filter out apps with zero usage time, sort by usage descending
      infoList.removeWhere((info) => info.usage.inSeconds <= 0);
      infoList.sort((a, b) => b.usage.compareTo(a.usage));

      setState(() {
        _infos = infoList;
        _isLoading = false;
      });
    } catch (exception) {
      print("Error fetching usage stats: $exception");
      setState(() {
        _isLoading = false;
        _error =
            "Failed to load usage stats.\nPlease ensure permissions are granted.";
        _infos = []; // Clear potentially stale data
      });
      // Optionally show a SnackBar for the error
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Helper method to get the app with the highest usage
  AppUsageInfo getMaxUsageApp(List<AppUsageInfo> infos) {
    if (infos.isEmpty) return infos[0];
    return infos.reduce(
      (a, b) => a.usage.inSeconds > b.usage.inSeconds ? a : b,
    );
  }

  // --- Builds the main content body ---
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    if (_infos.isEmpty) {
      return const Center(
        child: Text(
          'No app usage data found for the selected period.\n(Or permissions might be needed)',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Find the app with the maximum usage
    AppUsageInfo maxUsageApp = getMaxUsageApp(_infos);
    final int maxTime = maxUsageApp.usage.inSeconds;

    // Display the list of apps
    return ListView.builder(
      itemCount: _infos.length,
      itemBuilder: (context, index) {
        final info = _infos[index];

        // Check if the current app is the one with the highest usage
        final double percentage = info.usage.inSeconds / maxTime;

        // Return the column with the background bar behind the text
        return Column(
          children: [
            // The Stack widget to display the bar behind the text
            Stack(
              children: [
                // Background bar (light black color)
                Container(
                  height: 70.0, // Adjust height to fit your content
                  width: MediaQuery.of(context).size.width,
                  color: const Color.fromARGB(
                    80,
                    0,
                    0,
                    0,
                  ), // Light black background for the bar
                ),
                // Foreground bar (black color) based on usage percentage
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    height: 70.0, // Consistent height with background
                    width:
                        MediaQuery.of(context).size.width *
                        percentage, // Percentage width
                    color: Colors.black, // Color of the filled portion
                  ),
                ),
                // Text on top of the background bar, centered
                Positioned.fill(
                  child: Center(
                    child: Text(
                      "${info.appName}\n${formatDuration(info.usage)}", // Custom format for app name and usage
                      textAlign:
                          TextAlign.center, // Align the text in the center
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for contrast
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString =
        "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage Stats'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            "Usage for: $timeRangeString",
            style: TextStyle(
              fontSize: 20,
              color:
                  Theme.of(
                    context,
                  ).appBarTheme.foregroundColor?.withOpacity(0.8) ??
                  const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getUsageStats,
        tooltip: 'Refresh Stats',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// --- Main App Widget ---
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      home: AppUsageApp(),
    );
  }
}

void main() {
  runApp(MyApp());
}
