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

class _TabsState extends State<Tabs> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;
  bool _permissionsGranted = false;
  
  // Use lazy loading with late initialization for better performance
  // This ensures tabs are only created when needed and kept in memory
  late final List<Widget> _tabs = [
    const AppUsageApp(),
    const LocalLeaderboard(),
    const PermissionsTab(),
    RulesPage(),
  ];

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Use a microtask to check permissions after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }
  
  Future<void> _checkPermissions() async {
    // In a real app, you would check permissions here
    // For now, we'll just simulate that permissions are granted
    // This would normally involve checking with the native platform
    await Future.delayed(Duration(milliseconds: 500)); // Simulate check
    
    if (mounted) {
      setState(() {
        _permissionsGranted = true;
      });
    }
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
        body: Stack(
          children: [
            // Main content - use IndexedStack to prevent rebuilding of tabs
            // This is a key optimization for performance
            IndexedStack(
              index: _selectedIndex,
              sizing: StackFit.expand,
              children: _tabs,
            ),

            // Blocking overlay - only shown if permissions are not granted
            if (!_permissionsGranted)
              const ModalBarrier(
                dismissible: false,
                color: Colors.black87,
              ),
            if (!_permissionsGranted)
              Blocking(onPermissionsGranted: _handlePermissionsGranted),
          ],
        ),
        bottomNavigationBar: AnimatedOpacity(
          opacity: _permissionsGranted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
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
                if (mounted && _permissionsGranted) {
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
      ),
    );
  }
}
