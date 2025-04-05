import 'package:flutter/services.dart';

/// A service that monitors when specific applications are opened on the device.
///
/// This class utilizes Android's Accessibility Service to detect app launches
/// in real-time. It provides a clean interface for Flutter apps to monitor
/// when specific apps are opened by their package names.
///
/// Usage:
/// ```dart
/// final monitor = AppMonitor();
/// monitor.onAppOpened = (packageName) {
///   print('App opened: $packageName');
/// };
/// monitor.monitorApp('com.android.chrome');
/// ```
class AppMonitor {
  /// The method channel used to communicate with native Android code.
  ///
  /// This channel must match the one defined in the native Kotlin/Java code.
  /// It follows the pattern of reverse domain name notation (com.package.name/channel_name).
  static const MethodChannel _channel = MethodChannel('com.hugh.coughacks/app_monitor');
  
  /// Callback function that will be invoked when a monitored app is opened.
  ///
  /// The callback receives the package name of the opened app as a String parameter.
  /// This allows client code to identify which specific app was opened and take
  /// appropriate action.
  Function(String)? onAppOpened;
  
  /// Singleton instance of the AppMonitor.
  ///
  /// Using a singleton pattern ensures that only one instance of the AppMonitor
  /// exists throughout the application's lifecycle, preventing multiple listeners
  /// and potential resource leaks.
  static final AppMonitor _instance = AppMonitor._internal();
  
  /// Factory constructor that returns the singleton instance.
  ///
  /// This allows the class to be instantiated normally: `AppMonitor()`,
  /// while still ensuring only one instance exists.
  factory AppMonitor() {
    return _instance;
  }
  
  /// Private constructor that initializes the singleton instance.
  ///
  /// When the instance is created, it sets up the method call handler
  /// to receive events from the native Android code.
  AppMonitor._internal() {
    _setupMethodCallHandler();
  }
  
  /// Sets up a handler for method calls from the native platform.
  ///
  /// This establishes a communication channel from Android to Flutter,
  /// listening for specific method calls and reacting accordingly.
  /// The primary event listened for is 'onAppOpened', which triggers
  /// when a monitored app is detected as opened by the Accessibility Service.
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        // Called when the Accessibility Service detects that a monitored app has been opened
        case 'onAppOpened':
          final String packageName = call.arguments;
          print('App opened detected: $packageName');
          
          // Invoke the callback if it's registered
          onAppOpened?.call(packageName);
          break;
      }
      return null;
    });
  }
  
  /// Starts monitoring a specific application by its package name.
  ///
  /// When this app is opened, the [onAppOpened] callback will be triggered.
  ///
  /// Parameters:
  /// - [packageName]: The Android package name of the app to monitor (e.g., 'com.android.chrome')
  ///
  /// Returns:
  /// - [Future<bool>]: A Future that completes with true if the app was successfully
  ///   added to the monitoring list, or false if there was an error.
  ///
  /// Throws:
  /// - [PlatformException]: If there's an error in the native Android code.
  ///
  /// Note: The Accessibility Service must be enabled in system settings for this to work.
  Future<bool> monitorApp(String packageName) async {
    try {
      // Invoke the native method to add this package to the monitored list
      return await _channel.invokeMethod('monitorApp', {
        'packageName': packageName,
      }) ?? false;
    } catch (e) {
      print('Error monitoring app: $e');
      return false;
    }
  }
  
  /// Stops monitoring a previously monitored application.
  ///
  /// After calling this method, opening the specified app will no longer
  /// trigger the [onAppOpened] callback.
  ///
  /// Parameters:
  /// - [packageName]: The Android package name of the app to stop monitoring
  ///
  /// Returns:
  /// - [Future<bool>]: A Future that completes with true if the app was successfully
  ///   removed from the monitoring list, or false if there was an error.
  ///
  /// Throws:
  /// - [PlatformException]: If there's an error in the native Android code.
  Future<bool> stopMonitoringApp(String packageName) async {
    try {
      // Invoke the native method to remove this package from the monitored list
      return await _channel.invokeMethod('stopMonitoringApp', {
        'packageName': packageName,
      }) ?? false;
    } catch (e) {
      print('Error stopping app monitoring: $e');
      return false;
    }
  }
  
  /// Retrieves a list of all currently monitored app package names.
  ///
  /// This can be useful for showing the user which apps are currently being monitored,
  /// or for persisting the list across app restarts.
  ///
  /// Returns:
  /// - [Future<List<String>>]: A Future that completes with a list of package names
  ///   that are currently being monitored.
  ///
  /// Throws:
  /// - [PlatformException]: If there's an error in the native Android code.
  Future<List<String>> getMonitoredApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getMonitoredApps') ?? [];
      return result.cast<String>();
    } catch (e) {
      print('Error getting monitored apps: $e');
      return [];
    }
  }
  
  /// Opens the Android Accessibility Settings screen.
  ///
  /// This allows the user to enable the Accessibility Service needed for
  /// app monitoring to work. This should be called before attempting to
  /// monitor apps, typically after explaining to the user why the
  /// permission is needed.
  ///
  /// Throws:
  /// - [PlatformException]: If there's an error opening the settings.
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }
  
  /// Checks if the Accessibility Service is currently enabled.
  ///
  /// This can be used to determine if the app needs to prompt the user
  /// to enable the service before attempting to monitor apps.
  ///
  /// Returns:
  /// - [Future<bool>]: A Future that completes with true if the Accessibility
  ///   Service is enabled, or false if it's not.
  ///
  /// Throws:
  /// - [PlatformException]: If there's an error checking the service status.
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityServiceEnabled') ?? false;
    } catch (e) {
      print('Error checking accessibility service status: $e');
      return false;
    }
  }
}