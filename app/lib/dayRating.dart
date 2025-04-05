import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class Dayrating extends StatelessWidget {
  static const platform = MethodChannel('com.yourcompany.screenTime');

  Future<int> getScreenTime(int dayOffset) async {
    try {
      final int result = await platform.invokeMethod('getScreenTime', {'dayOffset': dayOffset});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get screen time: '${e.message}'.");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Screen Time')),
        body: Center(
          child: FutureBuilder<int>(
            future: getScreenTime(0), // 0 = Today
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else {
                return Text('Total screen time for today: ${snapshot.data} seconds');
              }
            },
          ),
        ),
      ),
    );
  }
}
