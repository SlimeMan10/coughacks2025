import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tabs.dart'; // Your main app screen
import 'method_channel.dart';
import 'services/permissions_data_service.dart'; // Import the permissions data service

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  int _currentPage = 0;
  final int _totalPages = 5;
  late PageController _pageController;

  bool _checkingPermissions = false;
  Timer? _permissionCheckTimer;
  Timer? _permissionsDataTimeout;
  bool _permissionsDataReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);

    // Check if permissions data is already loaded
    _checkPermissionsDataStatus();

    // Set a timeout for permissions data loading
    _permissionsDataTimeout = Timer(Duration(seconds: 10), () {
      print("Permissions data preload timed out, proceeding anyway");
      if (mounted) {
        setState(() => _permissionsDataReady = true);
      }
    });

    // Check permissions initially
    _checkAndNavigateIfPermissionsGranted();
  }

  void _checkPermissionsDataStatus() {
    final dataService = PermissionsDataService();

    // Add one-time listener for when data is loaded
    dataService.addDataLoadedListener(() {
      print("Permissions data preloaded successfully!");
      _permissionsDataTimeout?.cancel();
      if (mounted) {
        setState(() => _permissionsDataReady = true);
        // Try navigation in case permissions are already granted
        _checkAndNavigateIfPermissionsGranted();
      }
    });

    // If data is already loaded, mark as ready
    if (dataService.isLoaded) {
      print("Permissions data already loaded!");
      _permissionsDataTimeout?.cancel();
      if (mounted) {
        setState(() => _permissionsDataReady = true);
      }
    }
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
      print("Permissions data ready: $_permissionsDataReady");

      // Only navigate if all conditions are me
      if (accessibilityEnabled && overlayPermission && _permissionsDataReady) {
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

          // Page conten
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: ClampingScrollPhysics(),
              itemCount: _totalPages,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentPage = index;
                  });
                }
              },
              itemBuilder: (context, index) {
                if (index < 4) {
                  // First 4 screens are general onboarding
                  return OnboardingScreen(
                    title: "Screen ${index + 1}",
                    content: "${_getOrdinal(index + 1)} onboarding screen.",
                    onTapLeft: () => index > 0 ? _pageController.animateToPage(
                      index - 1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOu
                    ) : () {},
                    onTapRight: () => _pageController.animateToPage(
                      index + 1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOu
                    ),
                  );
                } else {
                  // Last screen is the permission screen
                  return _buildFinalScreen(screenWidth);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinal(int number) {
    switch(number) {
      case 1: return "First";
      case 2: return "Second";
      case 3: return "Third";
      case 4: return "Fourth";
      default: return "${number}th";
    }
  }

  Widget _buildFinalScreen(double screenWidth) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Info Conten
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
                curve: Curves.easeInOu
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

// Reusable Onboarding Screen Widge
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
        // Conten
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
