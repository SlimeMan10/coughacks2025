import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'AppUsage.dart'; // Make sure this exports AppUsageApp
=======
import 'AppUsage.dart';
import '/Wigit/blockInfo.dart';
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
      home: Scaffold(
        body: TabBarView(
          controller: _tabController,
          children: [
            AppUsageApp(),
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
              Tab(icon: Icon(Icons.one_x_mobiledata)),
=======
      home: DefaultTabController(
        length: 3,  // Updated to 3 tabs
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.bar_chart), text: "Usage"),
                Tab(icon: Icon(Icons.directions_transit), text: "Transit"),
                Tab(icon: Icon(Icons.block), text: "Block Info"),  // Added third tab
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: TabBarView(
            children: [
              AppUsageApp(), 
              const Center(child: Icon(Icons.directions_transit)),
              BlockInfo(title: 'Block Info'),
>>>>>>> Stashed changes
            ],
          ),
        ),
      ),
    );
  }
}
