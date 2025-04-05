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

      // Check if rule exists firs
      bool exists = await storage.ruleExists(rule.name);

      if (exists) {
        output.writeln('Rule with name "${rule.name}" already exists. Updating...');
        bool updateSuccess = await storage.updateRule(rule.name, rule);
        output.writeln(updateSuccess ? '✓ Updated rule: ${rule.name}' : '✗ Failed to update rule: ${rule.name}');
      } else {
        bool addSuccess = await storage.addRule(rule);
        output.writeln(addSuccess ? '✓ Added new rule: ${rule.name}' : '✗ Failed to add rule: ${rule.name}');
      }

      // Get all rules to verify
      var rules = await storage.getRules();
      output.writeln('\n=== All Stored Rules (${rules.length}) ===');
      if (rules.isEmpty) {
        output.writeln('No rules found in storage!');
      } else {
        for (var r in rules) {
          output.writeln('• ${r.name} - Blocks: ${r.blockedApps.length} apps');
          if (r.blockedApps.isNotEmpty) {
            output.writeln('  Apps: ${r.blockedApps.join(", ")}');
          }
          output.writeln('  Days: ${r.applicableDays.map((d) => d.toString().split('.').last).join(", ")}');
          if (r.isAllDay) {
            output.writeln('  Time: All day');
          } else {
            output.writeln('  Time: ${_formatTimeOfDay(r.startTime!)} - ${_formatTimeOfDay(r.endTime!)}');
          }
          output.writeln('  Strict mode: ${r.isStrict ? "Yes" : "No"}');
          output.writeln('');
        }
      }

      // Get the rule we just added to verify
      final retrievedRule = await storage.getRuleByName(rule.name);
      output.writeln('\n=== Retrieved Rule ===');
      if (retrievedRule != null) {
        output.writeln('✓ Successfully retrieved rule: ${retrievedRule.name}');
        output.writeln('• Blocks: ${retrievedRule.blockedApps.length} apps');
        output.writeln('• Days: ${retrievedRule.applicableDays.length} days selected');
        output.writeln('• All Day: ${retrievedRule.isAllDay ? "Yes" : "No"}');
        if (!retrievedRule.isAllDay) {
          output.writeln('• Time: ${_formatTimeOfDay(retrievedRule.startTime!)} - ${_formatTimeOfDay(retrievedRule.endTime!)}');
        }
        output.writeln('• Strict mode: ${retrievedRule.isStrict ? "Yes" : "No"}');

        // Verify data integrity
        bool nameMatch = retrievedRule.name == rule.name;
        bool appsMatch = _listsEqual(retrievedRule.blockedApps, rule.blockedApps);
        bool daysMatch = _listsEqual(
          retrievedRule.applicableDays.map((d) => d.toString()).toList(),
          rule.applicableDays.map((d) => d.toString()).toList()
        );
        bool allDayMatch = retrievedRule.isAllDay == rule.isAllDay;
        bool timeMatch = true;
        if (!rule.isAllDay) {
          timeMatch = retrievedRule.startTime?.hour == rule.startTime?.hour &&
                      retrievedRule.startTime?.minute == rule.startTime?.minute &&
                      retrievedRule.endTime?.hour == rule.endTime?.hour &&
                      retrievedRule.endTime?.minute == rule.endTime?.minute;
        }
        bool strictMatch = retrievedRule.isStrict == rule.isStrict;

        output.writeln('\n=== Data Integrity Check ===');
        output.writeln('• Name: ${nameMatch ? "✓" : "✗"}');
        output.writeln('• Apps: ${appsMatch ? "✓" : "✗"}');
        output.writeln('• Days: ${daysMatch ? "✓" : "✗"}');
        output.writeln('• All Day setting: ${allDayMatch ? "✓" : "✗"}');
        output.writeln('• Time settings: ${timeMatch ? "✓" : "✗"}');
        output.writeln('• Strict mode: ${strictMatch ? "✓" : "✗"}');

        bool allMatch = nameMatch && appsMatch && daysMatch && allDayMatch && timeMatch && strictMatch;
        output.writeln('\n${allMatch ? "✓ All data correctly saved and retrieved" : "✗ Some data was not correctly preserved"}');
      } else {
        output.writeln('✗ Failed to retrieve rule. Something went wrong.');
      }

      output.writeln('\n=== Test Complete ===');
      output.writeln('Timestamp: ${DateTime.now()}');
    } catch (e, stackTrace) {
      output.writeln('ERROR running tests: $e');
      output.writeln('Stack trace:');
      output.writeln(stackTrace.toString());
    }

    return output.toString();
  }

  static String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;

    // Create sorted copies to compare (if possible)
    final sortedList1 = List<T>.from(list1);
    final sortedList2 = List<T>.from(list2);

    try {
      sortedList1.sort();
      sortedList2.sort();

      for (int i = 0; i < sortedList1.length; i++) {
        if (sortedList1[i] != sortedList2[i]) return false;
      }

      return true;
    } catch (e) {
      // If sorting fails (not comparable), compare without sorting
      for (final item in list1) {
        if (!list2.contains(item)) return false;
      }
      return true;
    }
  }
}