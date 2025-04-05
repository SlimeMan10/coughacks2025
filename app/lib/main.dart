import 'package:flutter/material.dart';
// Remove the direct import for Tabs, it will be navigated to from Splash
// import 'tabs.dart';
import 'native_rule_bridge.dart';
import 'splash_screen.dart'; // Import the new splash screen file

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the NativeRuleBridge to handle method calls from native
  print('📱 THIS IS IN DART: Initializing NativeRuleBridge in main.dart');
  NativeRuleBridge.initialize();

  // Run the app, starting with the MaterialApp wrapping the SplashScreen
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockr', // Optional: App title
      theme: ThemeData(
        // Define a dark theme base if needed for consistency
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey, // Or another dark-friendly swatch
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: SplashScreen(), // Start with the splash screen
    );
  }
}

// Keep your Tabs widget in tabs.dart as it is.
// Keep your NativeRuleBridge in native_rule_bridge.dart as it is.