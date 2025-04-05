import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your rule and rule storage (adjust paths as needed)
import 'package:app/Rule.dart';  
import 'package:app/database/ruleDatabase.dart';

void main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== RuleStorage Test ===');
  
  try {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Create storage instance
    final storage = RuleStorage();
    
    // Clear any existing data
    await storage.clearAllRules();
    print('✓ Cleared all rules');
    
    // Test 1: Add rules
    final rule1 = Rule(
      name: "Work Focus",
      blockedApps: ["Instagram", "TikTok", "YouTube"],
      isAllDay: false,
      startTime: const TimeOfDay(hour: 9, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
      applicableDays: [
        DayOfWeek.Monday, DayOfWeek.Tuesday, DayOfWeek.Wednesday, 
        DayOfWeek.Thursday, DayOfWeek.Friday
      ],
      isStrict: true,
    );
    
    await storage.addRule(rule1);
    print('✓ Added rule: ${rule1.name}');
    
    final rule2 = Rule(
      name: "Weekend Detox",
      blockedApps: ["All"],
      isAllDay: true,
      applicableDays: [DayOfWeek.Saturday, DayOfWeek.Sunday],
      isStrict: false,
    );
    
    await storage.addRule(rule2);
    print('✓ Added rule: ${rule2.name}');
    
    // Test 2: Get all rules
    var rules = await storage.getRules();
    print('\n=== Stored Rules (${rules.length}) ===');
    for (var rule in rules) {
      print('• ${rule.name} - Blocks: ${rule.blockedApps.join(", ")}');
      print('  Days: ${rule.applicableDays.map((d) => d.toString().split('.').last).join(", ")}');
      if (rule.isAllDay) {
        print('  Time: All day');
      } else {
        print('  Time: ${_formatTimeOfDay(rule.startTime!)} - ${_formatTimeOfDay(rule.endTime!)}');
      }
      print('  Strict mode: ${rule.isStrict ? "Yes" : "No"}');
      print('');
    }
    
    // Test 3: Update a rule
    final updatedRule = rule1.copyWith(
      blockedApps: [...rule1.blockedApps, "Twitter"],
      isStrict: false,
    );
    
    await storage.updateRule(rule1.name, updatedRule);
    print('✓ Updated rule: ${rule1.name}');
    
    // Test 4: Get specific rule
    final retrievedRule = await storage.getRuleByName(rule1.name);
    print('\n=== Retrieved Rule ===');
    print('• ${retrievedRule?.name} - Blocks: ${retrievedRule?.blockedApps.join(", ")}');
    print('  Strict mode: ${retrievedRule?.isStrict == true ? "Yes" : "No"}');
    
    // Test 5: Check if rules exist
    print('\n=== Rule Existence Checks ===');
    print('• "Work Focus" exists: ${await storage.ruleExists("Work Focus")}');
    print('• "Nonexistent Rule" exists: ${await storage.ruleExists("Nonexistent Rule")}');
    
    // Test 6: Delete a rule
    await storage.deleteRule(rule2.name);
    print('\n✓ Deleted rule: ${rule2.name}');
    
    // Verify deletion
    rules = await storage.getRules();
    print('• Remaining rules: ${rules.length}');
    print('• Rules: ${rules.map((r) => r.name).join(", ")}');
    
    // Test 7: Test cache functionality
    print('\n=== Testing Cache ===');
    print('• Getting rules (should use cache)...');
    final startTime = DateTime.now();
    await storage.getRules();
    print('  Time: ${DateTime.now().difference(startTime).inMilliseconds}ms');
    
    print('• Clearing cache...');
    storage.clearCache();
    
    print('• Getting rules (should read from storage)...');
    final startTime2 = DateTime.now();
    await storage.getRules();
    print('  Time: ${DateTime.now().difference(startTime2).inMilliseconds}ms');
    
    print('\n=== Test Complete ===');
  } catch (e, stackTrace) {
    print('Error running tests: $e');
    print('Stack trace: $stackTrace');
  }
}

String _formatTimeOfDay(TimeOfDay timeOfDay) {
  final hour = timeOfDay.hour.toString().padLeft(2, '0');
  final minute = timeOfDay.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}