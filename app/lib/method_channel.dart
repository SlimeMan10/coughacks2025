import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.hugh/accessibility');


  static Future<void> requestOverlayPermission() async {
    await _channel.invokeMethod('requestOverlayPermission');
  }

  static Future<bool> hasOverlayPermission() async {
  return await _channel.invokeMethod('hasOverlayPermission');
}



  static Future<bool> isAccessibilityEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check accessibility: ${e.message}");
      return false;
    }
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print("Failed to open accessibility settings: $e");
    }
  }
}