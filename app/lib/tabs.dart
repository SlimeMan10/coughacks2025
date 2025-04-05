import 'package:app/Permissions.dart';
import 'package:flutter/material.dart';
import 'AppUsage.dart'; // Make sure this exports AppUsageApp

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: TabBarView(
          controller: _tabController,
          children: [
            AppUsageApp(),
            PermissionsTab(),
            Center(child: Icon(Icons.directions_transit, size: 64)),
          ],
        ),
        bottomNavigationBar: Material(
          color: Colors.white60,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 0, 0, 0),
            unselectedLabelColor: const Color.fromARGB(153, 83, 82, 82),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart)),
              Tab(icon: Icon(Icons.warning)),
              Tab(icon: Icon(Icons.one_x_mobiledata)),

            ],
          ),
        ),
      ),
    );
  }
}
