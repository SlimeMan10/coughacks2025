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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        body: TabBarView(
          controller: _tabController,
          children: [
            AppUsageApp(),
            PermissionsTab(),
            Blocking(),
            RulesPage(),
            BlockInfo(title: 'Block Info Placeholder'),
            LocalLeaderboard(),
          ],
        ),
        bottomNavigationBar: Container(
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
              Tab(icon: Icon(Icons.warning_amber_outlined)),
              Tab(icon: Icon(Icons.shield_outlined)),
              Tab(icon: Icon(Icons.handshake)),
              Tab(icon: Icon(Icons.block)),
              Tab(icon: Icon(Icons.abc),)
            ],
          ),
        ),
      ),
    );
  }
}
