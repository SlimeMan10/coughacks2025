import 'package:app/Permissions.dart';
import 'package:app/LocalLeaderboard.dart';
import 'package:app/blocking.dart';
import 'package:app/rulesPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'AppUsage.dart';
import 'blockInfo.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  int _selectedIndex = 0; // RulesPage is default
  
  static final List<Widget> _tabs = [
    AppUsageApp(),   // Home
    // BlockInfo(),     // Rules - moved from index 4 to 1 to match tabs order
    // Blocking(),      // Squads
    RulesPage(),    
    PermissionsTab(),
    LocalLeaderboard(),
  ];

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
      ),
      home: Scaffold(
        body: _tabs[_selectedIndex],
        bottomNavigationBar: Container(
          height: 83, // Match the height in screenshot
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8), // Light background color like in screenshot
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
              setState(() {
                _selectedIndex = index;
              });
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
                icon: Icon(CupertinoIcons.brightness),
                activeIcon: Icon(CupertinoIcons.brightness_solid),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.lock),
                activeIcon: Icon(CupertinoIcons.lock_fill),
                label: 'Rules',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.hand_raised),
                activeIcon: Icon(CupertinoIcons.hand_raised_fill),
                label: 'Permissions',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_fill),
                label: 'Leaderboard',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
