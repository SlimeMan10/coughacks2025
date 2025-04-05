import 'package:flutter/material.dart';
import 'database/ruleDatabase.dart';

enum DayOfWeek {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday
}

class Rule {
  final String name;
  final List<String> blockedApps;
  final bool isAllDay;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<DayOfWeek> applicableDays;
  final bool isStrict;

  Rule({
    required this.name,
    required this.blockedApps,
    required this.isAllDay,
    this.startTime,
    this.endTime,
    required this.applicableDays,
    required this.isStrict,
  }) : assert(
          isAllDay || (startTime != null && endTime != null),
          'startTime and endTime must be provided if isAllDay is false',
        );

  // Convert Rule to a Map (useful for storing in a database or serializing)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'blockedApps': blockedApps,
      'isAllDay': isAllDay,
      'startTime': isAllDay ? null : _timeOfDayToString(startTime!),
      'endTime': isAllDay ? null : _timeOfDayToString(endTime!),
      'applicableDays': applicableDays.map((day) => day.toString().split('.').last).toList(),
      'isStrict': isStrict,
    };
  }

  Map<String, dynamic> get information => toMap();

  // Create a Rule from a Map
  factory Rule.fromMap(Map<String, dynamic> map) {
    return Rule(
      name: map['name'],
      blockedApps: List<String>.from(map['blockedApps']),
      isAllDay: map['isAllDay'],
      startTime: map['startTime'] != null ? _stringToTimeOfDay(map['startTime']) : null,
      endTime: map['endTime'] != null ? _stringToTimeOfDay(map['endTime']) : null,
      applicableDays: (map['applicableDays'] as List)
          .map((day) => DayOfWeek.values.firstWhere(
                (d) => d.toString().split('.').last == day,
              ))
          .toList(),
      isStrict: map['isStrict'],
    );
  }

  // Helper method to convert TimeOfDay to String
  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to convert String to TimeOfDay
  static TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Clone the rule with potential modifications
  Rule copyWith({
    String? name,
    List<String>? blockedApps,
    bool? isAllDay,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<DayOfWeek>? applicableDays,
    bool? isStrict,
  }) {
    return Rule(
      name: name ?? this.name,
      blockedApps: blockedApps ?? this.blockedApps,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      applicableDays: applicableDays ?? this.applicableDays,
      isStrict: isStrict ?? this.isStrict,
    );
  }

  @override
  String toString() {
    return 'Rule{name: $name, blockedApps: $blockedApps, isAllDay: $isAllDay, '
        'startTime: ${isAllDay ? "N/A" : _timeOfDayToString(startTime!)}, '
        'endTime: ${isAllDay ? "N/A" : _timeOfDayToString(endTime!)}, '
        'applicableDays: ${applicableDays.map((d) => d.toString().split('.').last).join(', ')}, '
        'isStrict: $isStrict}';
  }

  // Get current TimeOfDay
  static TimeOfDay getCurrentTimeOfDay() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  // Get current day of week
  static DayOfWeek getCurrentDayOfWeek() {
    final now = DateTime.now();
    // DateTime weekday is 1-7 where 1 is Monday
    return DayOfWeek.values[now.weekday - 1];
  }

  // Check if rule is active right now
  bool isActiveNow() {
    final currentDay = getCurrentDayOfWeek();

    // Check if rule applies to current day
    if (!applicableDays.contains(currentDay)) {
      return false;
    }

    // If it's an all-day rule, it's active
    if (isAllDay) {
      return true;
    }

    // Check if current time is within the rule's time range
    final currentTime = getCurrentTimeOfDay();

    // Convert times to minutes since midnight for easier comparison
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime!.hour * 60 + startTime!.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    // Handle rules that span across midnigh
    if (startMinutes > endMinutes) {
      // e.g., 23:00 to 06:00
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      // e.g., 09:00 to 17:00
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }
}

// Utility function to check if an app is blocked based on the current rules
Future<bool> isAppBlocked(String app) async {
  final currentTime = Rule.getCurrentTimeOfDay();
  final currentDay = Rule.getCurrentDayOfWeek();
  final ruleStorage = RuleStorage();
  final rules = await ruleStorage.getRules();

  String timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  print("Checking if app '$app' is blocked at ${timeToString(currentTime)} on $currentDay");

  for (final rule in rules) {
    if (rule.isActiveNow()) {
      print("Rule '${rule.name}' is active now.");

      if (rule.blockedApps.contains("All") || rule.blockedApps.contains(app)) {
        print("App '$app' is blocked by rule '${rule.name}'");
        return true;
      } else {
        print("App '$app' is NOT blocked by rule '${rule.name}'");
      }
    } else {
      print("Rule '${rule.name}' is not active now.");
    }
  }

  print("App '$app' is not currently blocked.");
  return false;
}