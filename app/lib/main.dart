import 'package:flutter/material.dart';
import 'tabs.dart';
import 'native_rule_bridge.dart';
import 'package:flutter/services.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the NativeRuleBridge to handle method calls from native
  print('📱 THIS IS IN DART: Initializing NativeRuleBridge in main.dart');
  NativeRuleBridge.initialize();
  
  // Run the app
  runApp(Tabs());
}