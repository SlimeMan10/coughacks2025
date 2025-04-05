import 'package:app/Permissions.dart';
import 'package:app/LocalLeaderboard.dart';
import 'package:app/blocking.dart';
import 'package:app/rulesPage.dart';
import 'package:flutter/material.dart';
import 'AppUsage.dart';
import 'blockInfo.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Only 5 actual tabs now
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.white,
          secondary: Colors.grey[800],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            // Main content (TabBarView)
            Offstage(
              offstage: !_permissionsGranted, // Hide content if permissions not granted
              child: TabBarView(
                controller: _tabController,
                children: [
                  AppUsageApp(),
                  LocalLeaderboard(),
                  PermissionsTab(),
                  RulesPage(),
                  BlockInfo(),
                ],
              ),
            ),

            // Blocking overlay
            if (!_permissionsGranted)
              const ModalBarrier(
                dismissible: false,
                color: Colors.black87,
              ),
            if (!_permissionsGranted)
              Blocking(onPermissionsGranted: _handlePermissionsGranted),
          ],
        ),
        bottomNavigationBar: Offstage(
          offstage: !_permissionsGranted,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart)),
                Tab(icon: Icon(Icons.person)),
                Tab(icon: Icon(Icons.warning_amber_outlined)),
                Tab(icon: Icon(Icons.handshake)),
                Tab(icon: Icon(Icons.block)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
