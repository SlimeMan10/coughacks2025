import 'package:flutter/material.dart';
import 'AppUsage.dart';

class Tabs extends StatelessWidget {
  const Tabs({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.bar_chart)),
                Tab(icon: Icon(Icons.one_x_mobiledata)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              AppUsageApp(), 
              const Center(child: Icon(Icons.directions_transit)),
            ],
          ),
        ),
      ),
    );
  }
}