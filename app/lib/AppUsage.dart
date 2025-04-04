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
  // Let's make it configurable or display it
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
      // You can adjust this range (e.g., last 24 hours, today, last hour)
       _endDate = DateTime.now();
       _startDate = _endDate.subtract(const Duration(days: 1)); // Example: Last 24 hours

      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(_startDate, _endDate);

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
        _error = "Failed to load usage stats.\nPlease ensure permissions are granted.";
        _infos = []; // Clear potentially stale data
      });
       // Optionally show a SnackBar for the error
       if (mounted) { // Check if the widget is still in the tree
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(_error!),
               backgroundColor: Colors.redAccent,
             ),
           );
       }
    }
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
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
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
      ));
    }

    // Display the list of apps
    return ListView.builder(
      itemCount: _infos.length,
      itemBuilder: (context, index) {
        final info = _infos[index];
        // Potentially add an icon here in the future
        // Widget appIcon = Icon(Icons.android); // Placeholder
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 2.0,
          child: ListTile(
            // leading: appIcon, // Uncomment when you have icons
            title: Text(
              info.appName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis, // Handle long app names
            ),
            // subtitle: Text(info.packageName), // Optionally show package name
            trailing: Text(
              formatDuration(info.usage),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold),
            ),
            // Optional: Add onTap for more details later
            // onTap: () {
            //   // Navigate to a detail screen or show a dialog
            //   _showAppDetailsDialog(info);
            // },
          ),
        );
      },
    );
  }

  // --- Optional: Dialog to show more details ---
  // void _showAppDetailsDialog(AppUsageInfo info) {
  //   final dateFormat = DateFormat.yMd().add_jms(); // For formatting dates
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(info.appName),
  //       content: SingleChildScrollView( // In case content is long
  //         child: ListBody(
  //           children: <Widget>[
  //             Text('Package: ${info.packageName}'),
  //             const SizedBox(height: 8),
  //             Text('Total Usage: ${formatDuration(info.usage)}'),
  //             const SizedBox(height: 8),
  //             // Note: Start/End dates from the package might represent the query range,
  //             // not necessarily the first/last usage time within that range.
  //             // Use them cautiously or fetch more granular data if needed.
  //             Text('Query Start: ${dateFormat.format(info.startDate.toLocal())}'),
  //             Text('Query End: ${dateFormat.format(info.endDate.toLocal())}'),
  //           ],
  //         ),
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           child: const Text('Close'),
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Simple date formatting for the subtitle
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString =
        "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage Stats'),
        centerTitle: true,
        // Display the current time range being shown
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            "Usage for: $timeRangeString",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.8) ?? Colors.white70,
             ),
           ),
         ),
        // You can add actions here later, like changing the date range
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.calendar_today),
        //     onPressed: () { /* Implement date range picker */ },
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0), // Add padding below app bar subtitle
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getUsageStats, // Refresh data on press
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
        primarySwatch: Colors.indigo, // Changed theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Use Material 3 design
         colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigoAccent), // M3 color scheme
         appBarTheme: const AppBarTheme(
           elevation: 1.0, // Subtle shadow
           // backgroundColor: Colors.indigo, // M2 style
           // foregroundColor: Colors.white, // M2 style
         ),
         cardTheme: CardTheme(
            clipBehavior: Clip.antiAlias, // Nicer corners
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners for cards
           ),
         ),
      ),
      home: AppUsageApp(), // Use the improved app screen
    );
  }
}

// --- Entry Point ---
void main() {
  runApp(MyApp());
}