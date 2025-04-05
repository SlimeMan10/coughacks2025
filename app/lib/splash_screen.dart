import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tabs.dart'; // Your main app screen
import 'method_channel.dart';
import 'services/permissions_data_service.dart'; // Import the permissions data service
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
  Timer? _permissionCheckTimer;
  Timer? _permissionsDataTimeout;
  
  // Preloading status trackers (kept for background tracking)
  bool _permissionsDataReady = false;
  bool _appUsageDataReady = false;
  bool _installedAppsReady = false;
  bool _rulesDataReady = false;
  
  // Progress tracking
  double _preloadProgress = 0.0;
  String _loadingMessage = "Starting...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    
    // Start all preloading operations
    _startPreloading();
    
    // Set a fallback timeout
    _permissionsDataTimeout = Timer(Duration(seconds: 15), () {
      print("Preloading timed out, proceeding anyway");
      _forceCompletePreloading();
    });
    
    // Check permissions initially
    _checkAndNavigateIfPermissionsGranted();
  }
  
  void _startPreloading() async {
    // Start all preloading tasks in parallel
    _preloadPermissionsData();
    _preloadAppUsageData();
    _preloadInstalledApps();
    _preloadRulesData();
  }
  
  void _updatePreloadProgress(String message, {double progressIncrement = 0.05}) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
        _preloadProgress = min(1.0, _preloadProgress + progressIncrement);
      });
    }
  }
  
  void _preloadPermissionsData() {
    final dataService = PermissionsDataService();
    
    // Add one-time listener for when data is loaded
    dataService.addDataLoadedListener(() {
      print("Permissions data preloaded successfully!");
      setState(() {
        _permissionsDataReady = true;
      });
      _checkIfAllPreloaded();
    });
    
    // If data is already loaded, mark as ready
    if (dataService.isLoaded) {
      print("Permissions data already loaded!");
      setState(() {
        _permissionsDataReady = true;
      });
      _checkIfAllPreloaded();
    }
  }
  
  void _preloadAppUsageData() async {
    try {
      // Preload app usage data for the last week
      final now = DateTime.now();
      final lastWeek = now.subtract(Duration(days: 7));
      
      await AppUsage().getAppUsage(lastWeek, now);
      
      setState(() {
        _appUsageDataReady = true;
      });
      print("App usage data preloaded successfully");
    } catch (e) {
      print("Error preloading app usage data: $e");
      // Consider it ready anyway to not block UI
      setState(() {
        _appUsageDataReady = true;
      });
    }
    
    _checkIfAllPreloaded();
  }
  
  void _preloadInstalledApps() async {
    try {
      await InstalledApps.getInstalledApps(false, true, "");
      
      setState(() {
        _installedAppsReady = true;
      });
      print("Installed apps data preloaded successfully");
    } catch (e) {
      print("Error preloading installed apps: $e");
      // Consider it ready anyway to not block UI
      setState(() {
        _installedAppsReady = true;
      });
    }
    
    _checkIfAllPreloaded();
  }
  
  void _preloadRulesData() async {
    try {
      final RuleStorage ruleStorage = RuleStorage();
      await ruleStorage.getRules();
      
      setState(() {
        _rulesDataReady = true;
      });
      print("Rules data preloaded successfully");
    } catch (e) {
      print("Error preloading rules data: $e");
      // Consider it ready anyway to not block UI
      setState(() {
        _rulesDataReady = true;
      });
    }
    
    _checkIfAllPreloaded();
  }
  
  void _checkIfAllPreloaded() {
    if (_permissionsDataReady && _appUsageDataReady && _installedAppsReady && _rulesDataReady) {
      _permissionsDataTimeout?.cancel();
      print("All data loaded successfully!");
      // Check if we can navigate based on permissions
      _checkAndNavigateIfPermissionsGranted();
    }
  }
  
  void _forceCompletePreloading() {
    setState(() {
      _permissionsDataReady = true;
      _appUsageDataReady = true;
      _installedAppsReady = true;
      _rulesDataReady = true;
    });
    _checkAndNavigateIfPermissionsGranted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check permissions when app is resumed (after potentially granting permissions)
      _checkAndNavigateIfPermissionsGranted();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _permissionCheckTimer?.cancel();
    _permissionsDataTimeout?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigateIfPermissionsGranted() async {
    if (_checkingPermissions) return;
    
    _checkingPermissions = true;
    
    try {
      final bool accessibilityEnabled = await NativeBridge.isAccessibilityEnabled();
      final bool overlayPermission = await NativeBridge.hasOverlayPermission();
      
      print("Accessibility enabled: $accessibilityEnabled");
      print("Overlay permission: $overlayPermission");
      print("All data preloaded: ${_permissionsDataReady && _appUsageDataReady && _installedAppsReady && _rulesDataReady}");
      
      // Only navigate if all conditions are met
      final bool allDataReady = _permissionsDataReady && _appUsageDataReady && 
                               _installedAppsReady && _rulesDataReady;
      
      if (accessibilityEnabled && overlayPermission && allDataReady) {
        _navigateToHome();
      } else if (mounted) {
        // If permissions not granted, schedule a check after a short delay
        _permissionCheckTimer?.cancel();
        _permissionCheckTimer = Timer(const Duration(seconds: 2), () {
          _checkingPermissions = false;
          _checkAndNavigateIfPermissionsGranted();
        });
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
            child: Container(
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
                // Screen 1 - Basic Introduction
                OnboardingScreen(
                  title: "Screen 1",
                  content: "First onboarding screen.",
                  onTapLeft: () => {}, // Do nothing on first screen
                  onTapRight: () => _pageController.animateToPage(
                    1, 
                    duration: Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  ),
                ),
                
                // Screen 2
                OnboardingScreen(
                  title: "Screen 2",
                  content: "Second onboarding screen.",
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
                
                // Screen 3
                OnboardingScreen(
                  title: "Screen 3",
                  content: "Third onboarding screen.",
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
                
                // Screen 4
                OnboardingScreen(
                  title: "Screen 4",
                  content: "Fourth onboarding screen.",
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
                      "Blockr",
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
                      title: "Welcome to Blockr",
                      content: "The all-in-one privacy app for your phone!",
                    ),
                    const SizedBox(height: 12),
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
                      "To get started, you must give some permissions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        _requestPermissionsAndNavigate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Let's Go!",
                        style: TextStyle(fontSize: 18),
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
      // Permissions already granted, navigate directly
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
    
    // Start checking permissions after a short delay
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = Timer(const Duration(seconds: 1), () {
      _checkingPermissions = false;
      _checkAndNavigateIfPermissionsGranted();
    });
  }
}

// Reusable Onboarding Screen Widget
class OnboardingScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;

  const OnboardingScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.onTapLeft,
    required this.onTapRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
