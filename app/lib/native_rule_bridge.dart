import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Rule.dart';
import 'database/ruleDatabase.dart';

class NativeRuleBridge {
  static const MethodChannel _channel = MethodChannel('com.hugh.coughacks/rule_check');
  static bool _initialized = false;
  static final RuleStorage _ruleStorage = RuleStorage();

  // Initialize the bridge to handle incoming calls from native
  static void initialize() {
    if (!_initialized) {
      _channel.setMethodCallHandler(_handleMethodCall);
      print('🔌 THIS IS IN DART: NativeRuleBridge initialized and ready to handle native calls');
      _initialized = true;
    }
  }

  // Handle method calls from native code
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('📲 THIS IS IN DART: Received call from native: ${call.method}');
    
    switch (call.method) {
      case 'checkAppAgainstRules':
        final String packageName = call.arguments;
        print('🔍 THIS IS IN DART: Checking app against rules: $packageName');
        final result = await _checkAppAgainstRules(packageName);
        print('📊 THIS IS IN DART: App $packageName is ${result['blocked'] ? "BLOCKED" : "ALLOWED"} by rules');
        return result;
      default:
        print('⚠️ THIS IS IN DART: Unknown method call from native: ${call.method}');
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented'
        );
    }
  }

  // Internal method to check app against rules
  static Future<Map<String, dynamic>> _checkAppAgainstRules(String packageName) async {
    print('🧮 THIS IS IN DART: Evaluating rules for app: $packageName');
    final rules = await _ruleStorage.getRules();
    
    for (final rule in rules) {
      final bool isActive = rule.isActiveNow();
      var containsApp = rule.blockedApps.contains(packageName);
      if (isActive) {
        print("THESE ARE ACTIVE RULES");
        print(rule.blockedApps);
      }

      for (var eachRule in rule.blockedApps) {
        if (packageName.toLowerCase().contains(eachRule.toLowerCase())) {
          containsApp = true;
          print(packageName.toLowerCase() + " contains " + eachRule.toLowerCase());
        }
      }
      
      print('📝 THIS IS IN DART: Rule "${rule.name}" is ${isActive ? "active" : "inactive"} and ${containsApp ? "blocks" : "doesn\'t block"} $packageName');
      
      if (isActive && containsApp) {
        print('🚫 THIS IS IN DART: App $packageName should be blocked by rule "${rule.name}"');
        return {
          'blocked': true,
          'ruleName': rule.name,
        };
      }
    }
    
    print('✅ THIS IS IN DART: No active rules block app: $packageName');
    return {
      'blocked': false,
      'ruleName': '',
    };
  }

  // Check if an app is currently blocked (called from Flutter code)
  static Future<bool> isAppCurrentlyBlocked(String packageName) async {
    print('🔍 THIS IS IN DART: Checking if app is currently blocked: $packageName');
    try {
      final bool result = await _channel.invokeMethod('isAppCurrentlyBlocked', {'app': packageName});
      print('📱 THIS IS IN DART: Native → Flutter response: App $packageName is ${result ? "BLOCKED ❌" : "ALLOWED ✅"}');
      return result;
    } on PlatformException catch (e) {
      print('❌ THIS IS IN DART: Error checking if app is blocked: ${e.message}');
      return false;
    }
  }
}

// Example: Checking if an app should be blocked based on rules
Future<void> checkAndBlockApp(String packageName) async {
  print('📋 THIS IS IN DART: Checking rules for app: $packageName');
  // First check Flutter rules
  final ruleStorage = RuleStorage();
  final rules = await ruleStorage.getRules();
  
  String blockingRuleName = '';
  bool shouldBlock = false;
  
  for (final rule in rules) {
    final bool isActive = rule.isActiveNow();
    final bool containsApp = rule.blockedApps.contains(packageName);
    
    print('🔍 THIS IS IN DART: Rule "${rule.name}" is ${isActive ? "active" : "inactive"} and ${containsApp ? "blocks" : "doesn\'t block"} $packageName');
    
    if (isActive && containsApp) {
      print('🚫 THIS IS IN DART: App $packageName should be blocked by rule "${rule.name}"');
      shouldBlock = true;
      blockingRuleName = rule.name;
      break;
    }
  }
  
  if (shouldBlock) {
    print('📲 THIS IS IN DART: Telling native side to block app: $packageName');
    // Use the bridge to tell the native side this app should be blocked
    final bool success = await NativeRuleBridge.isAppCurrentlyBlocked(packageName);
    print('📋 THIS IS IN DART: Native response for blocking $packageName: ${success ? "SUCCESS" : "FAILED"}');
  } else {
    print('✅ THIS IS IN DART: No rules found to block app: $packageName');
  }
}