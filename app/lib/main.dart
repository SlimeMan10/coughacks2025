import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

void main() => runApp(AppUsageApp());

class AppUsageApp extends StatefulWidget {
  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp> {
  List<AppUsageInfo> _infos = [];

  @override
  void initState() {
    super.initState();
  }

  void getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(hours: 1));
      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);
      setState(() => _infos = infoList);
    } catch (exception) {
      print(exception);
    }
  }

void printAppUsageInfo(AppUsageInfo info) {
  final appName = info.appName;
  final packageName = info.packageName;
  final startTime = info.startDate;
  final endTime = info.endDate;
  final duration = info.usage;

  print('📱 App Usage Info');
  print('--------------------');
  print('App Name     : $appName');
  print('Package Name : $packageName');
  print('Start Time   : ${startTime.toLocal()}');
  print('End Time     : ${endTime.toLocal()}');
  print('Duration     : ${_formatDuration(duration)}');
  print('--------------------\n');
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$seconds';
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Usage Example'),
          backgroundColor: Colors.green,
        ),
        body: ListView.builder(
            itemCount: _infos.length,
            itemBuilder: (context, index) {
              return ListTile(
                  title: Text(_infos[index].appName),
                  subtitle: Text(_infos[index].usage.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => printAppUsageInfo(_infos[index]),
                    child: Text("Print"),
                  ),);
            }),
        floatingActionButton: FloatingActionButton(
            onPressed: getUsageStats, child: Icon(Icons.file_download)),
      ),
    );
  }
}