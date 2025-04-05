import 'package:flutter/material.dart';
// Remove the direct import for Tabs, it will be navigated to from Splash
// import 'tabs.dart';
import 'native_rule_bridge.dart';
import 'splash_screen.dart'; // Import the new splash screen file
import 'services/permissions_data_service.dart'; // Import the permissions data service
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'database/ruleDatabase.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the NativeRuleBridge to handle method calls from native
  print('📱 THIS IS IN DART: Initializing NativeRuleBridge in main.dart');
  NativeRuleBridge.initialize();

  // Start all preloading operations in parallel immediately, but silently
  print('🔄 THIS IS IN DART: Starting data preloading (background)');
  
  // Preload permissions data
  final permissionsPreload = PermissionsDataService().preloadData();
  
  // Preload other data in parallel (will continue in background)
  // These futures don't need to be awaited - they'll continue in the background
  // and the splash screen will track their completion
  _preloadAppUsageData();
  _preloadInstalledApps();
  _preloadRulesData();

  // Run the app, starting with the MaterialApp wrapping the SplashScreen
  runApp(MyApp());
}

// Preload app usage data for the last week
Future<void> _preloadAppUsageData() async {
  print('📊 THIS IS IN DART: Preloading app usage data (background)');
  try {
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));
    await AppUsage().getAppUsage(lastWeek, now);
    print('✅ THIS IS IN DART: App usage data preloaded');
  } catch (e) {
    print('❌ THIS IS IN DART: Error preloading app usage data: $e');
  }
}

// Preload all installed apps
Future<void> _preloadInstalledApps() async {
  print('📱 THIS IS IN DART: Preloading installed apps (background)');
  try {
    await InstalledApps.getInstalledApps(false, true, "");
    print('✅ THIS IS IN DART: Installed apps preloaded');
  } catch (e) {
    print('❌ THIS IS IN DART: Error preloading installed apps: $e');
  }
}

// Preload rules from database
Future<void> _preloadRulesData() async {
  print('📋 THIS IS IN DART: Preloading rules data (background)');
  try {
    final ruleStorage = RuleStorage();
    await ruleStorage.getRules();
    print('✅ THIS IS IN DART: Rules data preloaded');
  } catch (e) {
    print('❌ THIS IS IN DART: Error preloading rules data: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockr', // Optional: App title
      theme: ThemeData(
        // Define a dark theme base if needed for consistency
        brightness: Brightness.light,
        primarySwatch: Colors.blueGrey, // Or another dark-friendly swatch
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: SplashScreen(), // Start with the splash screen
    );
  }
}

// Keep your Tabs widget in tabs.dart as it is.
// Keep your NativeRuleBridge in native_rule_bridge.dart as it is.