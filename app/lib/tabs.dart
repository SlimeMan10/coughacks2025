import 'package:app/Permissions.dart';
import 'package:app/LocalLeaderboard.dart';
import 'package:app/blocking.dart';
import 'package:app/rulesPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'AppUsage.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _permissionsGranted = false;

  // Define all tabs with a more state-efficient approach
  late final List<Widget> _tabs = [
    const AppUsageApp(),
    const LocalLeaderboard(),
    const PermissionsTab(),
    RulesPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handlePermissionsGranted() {
    if (mounted) {
      setState(() {
        _permissionsGranted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.black,
          secondary: Colors.grey[800],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main content - use IndexedStack to prevent rebuilding of tabs
              IndexedStack(
                index: _selectedIndex,
                sizing: StackFit.expand,
                children: _tabs,
              ),

              // Blocking overlay - only show if permissions not granted
              if (!_permissionsGranted)
                const ModalBarrier(
                  dismissible: false,
                  color: Colors.black87,
                ),
              if (!_permissionsGranted)
                Blocking(onPermissionsGranted: _handlePermissionsGranted),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 83,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                spreadRadius: 0,
                blurRadius: 0.5,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (mounted) {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black54,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chart_bar),
                activeIcon: Icon(CupertinoIcons.chart_bar_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_fill),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.hand_raised),
                activeIcon: Icon(CupertinoIcons.hand_raised_fill),
                label: 'Permissions',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.lock),
                activeIcon: Icon(CupertinoIcons.lock_fill),
                label: 'Rules',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
