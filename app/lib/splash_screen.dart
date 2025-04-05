import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tabs.dart'; // Your main app screen
import 'method_channel.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'database/ruleDatabase.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  int _currentPage = 0;
  final int _totalPages = 5;
  late PageController _pageController;
  
  // Loading states
  bool _checkingPermissions = false;
  
  // Progress tracking
  double _preloadProgress = 0.0;
  String _loadingMessage = "Starting...";
  bool _showDebugLoading = false; // For debugging loading status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    
    // Check permissions initially
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Immediately check permissions when app is resumed (after returning from settings)
      _checkPermissions();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // Just check if permissions are granted, no waiting
  Future<void> _checkPermissions() async {
    if (_checkingPermissions) return;
    
    _checkingPermissions = true;
    
    try {
      final bool accessibilityEnabled = await NativeBridge.isAccessibilityEnabled();
      final bool overlayPermission = await NativeBridge.hasOverlayPermission();
      
      print("Accessibility enabled: $accessibilityEnabled");
      print("Overlay permission: $overlayPermission");
      
      // If permissions are granted, immediately navigate to home
      if (accessibilityEnabled && overlayPermission) {
        _navigateToHome();
      }
    } catch (e) {
      print("Error checking permissions: $e");
    } finally {
      if (mounted) {
        _checkingPermissions = false;
      }
    }
  }

  void _navigateToHome() {
    print("Navigating to home");
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Tabs(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 24, right: 24, bottom: 16),
            child: Column(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: max(0, (_currentPage + 1) / _totalPages * (screenWidth - 48)),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: ClampingScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Screen 1 - The Hook
                OnboardingScreen(
                  title: "The Hook — We're All Glued to Our Screens",
                  emoji: "📱",
                  useBoxedIcon: false,
                  content: "",
                  bulletPoints: [
                    '61% of people admit they\'re addicted to their phones.',
                    'The average person taps their screen over 2,617 times a day.',
                    'We\'re living in a world of constant distraction — and it\'s costing us.',
                  ],
                  onTapLeft: () => {}, // Do nothing on first screen
                  onTapRight: () => _pageController.animateToPage(
                    1, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                ),
                
                // Screen 2 - What It's Costing You
                OnboardingScreen(
                  title: "What It's Costing You",
                  emoji: "⏳",
                  useBoxedIcon: false,
                  content: "",
                  bulletPoints: [
                    'The average young adult spends 7+ hours a day on screens.',
                    'That\'s over 11 years of your lifetime — lost.',
                    'Time we could spend learning, creating, or just being present.',
                  ],
                  onTapLeft: () => _pageController.animateToPage(
                    0, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                  onTapRight: () => _pageController.animateToPage(
                    2, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                ),
                
                // Screen 3 - The Hidden Trade-Off
                OnboardingScreen(
                  title: "The Hidden Trade-Off — Your Data",
                  emoji: "🔒",
                  useBoxedIcon: false,
                  content: "",
                  bulletPoints: [
                    '87% of apps share your data with third parties.',
                    'Some even record your microphone while you\'re not using them.',
                    'You\'re not just losing time — you\'re giving away your privacy.',
                  ],
                  onTapLeft: () => _pageController.animateToPage(
                    1, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                  onTapRight: () => _pageController.animateToPage(
                    3, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                ),
                
                // Screen 4 - Take Back Control
                OnboardingScreen(
                  title: "Take Back Control",
                  emoji: null,
                  useBoxedIcon: false,
                  content: "We built this app to help you:",
                  bulletPoints: [
                    '✅  Track screen time',
                    '✅  Block distractions',
                    '✅  Expose privacy risks',
                    '✅  Reclaim your focus and your freedom',
                    'Let\'s take back control.',
                  ],
                  customWidget: _buildShieldIcon(),
                  onTapLeft: () => _pageController.animateToPage(
                    2, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                  onTapRight: () => _pageController.animateToPage(
                    4, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                  extraBottomPadding: true,
                ),
                
                // Screen 5 - Redesigned Final Screen with white aesthetic
                _buildFinalScreen(screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinalScreen(double screenWidth) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Info Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 80, 
                      color: Colors.black87
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Cura",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info blocks with new style
                    _infoBlock(
                      title: "📊 Usage Stats",
                      content: "Game-ified usage data with smart data warnings.",
                    ),
                    _infoBlock(
                      title: "🔐 Permission Control",
                      content: "Swipe-based UI for reviewing and fixing permissions fast.",
                    ),
                    _infoBlock(
                      title: "🚫 App Blocking",
                      content: "Flexible rules to stop procrastination, not productivity.",
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "To get started, please enable",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: "Screen Time",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(text: " and "),
                          TextSpan(
                            text: "Accessibility",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(text: " access"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Cura never stores your data; permissions are only used to monitor usage locally on your device.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () {
                        _requestPermissionsAndNavigate();
                      },
                      icon: Icon(Icons.security, size: 24),
                      label: Text(
                        "Grant Access",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Left nav area (return to screen 4)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: screenWidth / 2,
            child: GestureDetector(
              onTap: () => _pageController.animateToPage(
                3, 
                duration: Duration(milliseconds: 300), 
                curve: Curves.easeInOut
              ),
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black
            )
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14, 
              color: Colors.black87, 
              height: 1.4
            )
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionsAndNavigate() async {
    // First check if permissions are already granted
    final bool accessibilityEnabled = await NativeBridge.isAccessibilityEnabled();
    final bool overlayPermission = await NativeBridge.hasOverlayPermission();
    
    if (accessibilityEnabled && overlayPermission) {
      // Permissions already granted, navigate directly to home
      _navigateToHome();
      return;
    }
    
    // Request any missing permissions
    if (!accessibilityEnabled) {
      await NativeBridge.openAccessibilitySettings();
    }
    
    if (!overlayPermission) {
      await Future.delayed(const Duration(milliseconds: 500));
      await NativeBridge.requestOverlayPermission();
    }
  }

  Widget _buildShieldIcon() {
    return Container(
      width: 160,
      height: 160,
      child: Center(
        child: Text(
          "🧭",
          style: TextStyle(
            fontSize: 100,
          ),
        ),
      ),
    );
  }
}

// Reusable Onboarding Screen Widget
class OnboardingScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final String? emoji;
  final List<String>? bulletPoints;
  final bool useBoxedIcon;
  final Widget? customWidget;
  final bool extraBottomPadding;

  const OnboardingScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.onTapLeft,
    required this.onTapRight,
    this.emoji,
    this.bulletPoints,
    this.useBoxedIcon = false,
    this.customWidget,
    this.extraBottomPadding = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Stack(
      children: [
        // Content
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.12),
                if (emoji != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    child: Text(
                      emoji!,
                      style: const TextStyle(
                        fontSize: 100,
                      ),
                    ),
                  ),
                if (customWidget != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    child: customWidget,
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.2,
                    fontFamily: 'SF Pro Display, -apple-system, BlinkMacSystemFont, sans-serif',
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                      height: 1.4,
                      fontFamily: 'SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (bulletPoints != null) ...[
                  const SizedBox(height: 40),
                  ...bulletPoints!.map((point) => Padding(
                    padding: EdgeInsets.only(bottom: bulletPoints!.last == point && extraBottomPadding ? 50 : 25),
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.black87,
                        height: 1.4,
                        fontFamily: 'SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )).toList(),
                ],
                SizedBox(height: screenHeight * (extraBottomPadding ? 0.22 : 0.2)),
              ],
            ),
          ),
        ),
        
        // Left half for going back
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: screenWidth / 2,
          child: GestureDetector(
            onTap: onTapLeft,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        
        // Right half for going forward
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: screenWidth / 2,
          child: GestureDetector(
            onTap: onTapRight,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({Key? key}) : super(key: key);

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> {
  bool _appUsagePreloaded = false;
  
  @override
  void initState() {
    super.initState();
    // Immediately start preloading app usage data
    _preloadAppUsageData();
  }
  
  // Preload app usage data to ensure it's ready when the user continues
  Future<void> _preloadAppUsageData() async {
    print("Preloading AppUsage data from ReadyScreen");
    
    try {
      // Create the Tabs instance early but don't display it
      final tabs = Tabs();
      
      // Preload app usage data for the last week
      final now = DateTime.now();
      final lastWeek = now.subtract(Duration(days: 7));
      
      // Fetch the app usage data
      print("Fetching app usage data in ReadyScreen...");
      final usage = await AppUsage().getAppUsage(lastWeek, now);
      print("ReadyScreen: Successfully preloaded ${usage.length} app records");
      
      // Preload installed apps list
      final apps = await InstalledApps.getInstalledApps(false, true, "");
      print("ReadyScreen: Successfully preloaded ${apps.length} installed apps");
      
      setState(() {
        _appUsagePreloaded = true;
      });
      print("AppUsage data fully preloaded and ready for navigation");
    } catch (e) {
      print("Error preloading app usage data in ReadyScreen: $e");
      // Consider it ready anyway to not block navigation
      setState(() {
        _appUsagePreloaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shield,
                      size: 80,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Main title
                Text(
                  "Ready to take back control?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Description
                Text(
                  "You're all set up with the permissions needed. Cura is ready to help you regain control of your screen time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Continue button - Direct navigation to Tabs with fade transition
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print("Continue button pressed in ReadyScreen");
                      if (!_appUsagePreloaded) {
                        print("AppUsage data still loading, but proceeding with navigation");
                      }
                      
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => Tabs(),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.arrow_forward,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: Text(
                      _appUsagePreloaded ? "Continue" : "Preparing...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                
                // Very subtle loading indicator if data isn't loaded yet
                if (!_appUsagePreloaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      "Setting up app data...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
