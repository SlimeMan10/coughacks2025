// lib/AppMonitor.dart
import 'package:flutter/services.dart';

class AppMonitor {
  static const MethodChannel _channel = MethodChannel('com.hugh.coughacks/app_monitor');
  
  // Callback for when a monitored app is opened
  Function(String)? onAppOpened;
  
  // Singleton pattern
  static final AppMonitor _instance = AppMonitor._internal();
  
  factory AppMonitor() {
    return _instance;
  }
  
  AppMonitor._internal() {
    _setupMethodCallHandler();
  }
  
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAppOpened':
          final String packageName = call.arguments;
          print('App opened: $packageName');
          onAppOpened?.call(packageName);
          break;
      }
      return null;
    });
  }
  
  // Start monitoring an app
  Future<bool> monitorApp(String packageName) async {
    try {
      return await _channel.invokeMethod('monitorApp', {
        'packageName': packageName,
      }) ?? false;
    } catch (e) {
      print('Error monitoring app: $e');
      return false;
    }
  }
  
  // Stop monitoring an app
  Future<bool> stopMonitoringApp(String packageName) async {
    try {
      return await _channel.invokeMethod('stopMonitoringApp', {
        'packageName': packageName,
      }) ?? false;
    } catch (e) {
      print('Error stopping app monitoring: $e');
      return false;
    }
  }
  
  // Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }
}