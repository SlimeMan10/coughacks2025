import 'package:flutter/material.dart';
import '../Rule.dart';
import 'ruleDatabase.dart';

class RuleStorageTestUtil {
  static Future<String> testRuleStorage(Rule rule) async {
    final StringBuffer output = StringBuffer();
    
    output.writeln('=== Rule Storage Test ===');
    output.writeln('${DateTime.now()}');
    output.writeln('');
    
    try {
      // Create storage instance
      final storage = RuleStorage();
      
      // Add the new rule (don't clear other rules)
      output.writeln('Testing with rule: ${rule.name}');
      output.writeln('• Blocks: ${rule.blockedApps.join(", ")}');
      output.writeln('• Days: ${rule.applicableDays.map((d) => d.toString().split('.').last).join(", ")}');
      if (rule.isAllDay) {
        output.writeln('• Time: All day');
      } else {
        output.writeln('• Time: ${_formatTimeOfDay(rule.startTime!)} - ${_formatTimeOfDay(rule.endTime!)}');
      }
      output.writeln('• Strict mode: ${rule.isStrict ? "Yes" : "No"}');
      output.writeln('');
      
      // Check if rule exists first
      bool exists = await storage.ruleExists(rule.name);
      
      if (exists) {
        output.writeln('Rule with name "${rule.name}" already exists. Updating...');
        await storage.updateRule(rule.name, rule);
        output.writeln('✓ Updated rule: ${rule.name}');
      } else {
        await storage.addRule(rule);
        output.writeln('✓ Added new rule: ${rule.name}');
      }
      
      // Get all rules to verify
      var rules = await storage.getRules();
      output.writeln('\n=== All Stored Rules (${rules.length}) ===');
      for (var r in rules) {
        output.writeln('• ${r.name} - Blocks: ${r.blockedApps.join(", ")}');
        output.writeln('  Days: ${r.applicableDays.map((d) => d.toString().split('.').last).join(", ")}');
        if (r.isAllDay) {
          output.writeln('  Time: All day');
        } else {
          output.writeln('  Time: ${_formatTimeOfDay(r.startTime!)} - ${_formatTimeOfDay(r.endTime!)}');
        }
        output.writeln('  Strict mode: ${r.isStrict ? "Yes" : "No"}');
        output.writeln('');
      }
      
      // Get the rule we just added to verify
      final retrievedRule = await storage.getRuleByName(rule.name);
      output.writeln('\n=== Retrieved Rule ===');
      if (retrievedRule != null) {
        output.writeln('• ${retrievedRule.name} - Blocks: ${retrievedRule.blockedApps.join(", ")}');
        output.writeln('• Applicable days: ${retrievedRule.applicableDays.length}');
        output.writeln('• Strict mode: ${retrievedRule.isStrict ? "Yes" : "No"}');
        output.writeln('✓ Rule successfully saved and retrieved');
      } else {
        output.writeln('✗ Failed to retrieve rule. Something went wrong.');
      }
      
      output.writeln('\n=== Test Complete ===');
    } catch (e, stackTrace) {
      output.writeln('Error running tests: $e');
      output.writeln('Stack trace: $stackTrace');
    }
    
    return output.toString();
  }
  
  static String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}