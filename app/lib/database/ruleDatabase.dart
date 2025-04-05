import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Rule.dart';

class RuleStorage {
  static const String _rulesKey = 'app_rules';

  // In-memory cache of rules
  List<Rule>? _cachedRules;

  // Singleton pattern
  static final RuleStorage _instance = RuleStorage._internal();

  factory RuleStorage() {
    return _instance;
  }

  RuleStorage._internal();

  // Get all rules
  Future<List<Rule>> getRules() async {
    // Return cached rules if available
    if (_cachedRules != null) {
      return _cachedRules!;
    }

    // Otherwise, load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getStringList(_rulesKey);

    if (rulesJson == null || rulesJson.isEmpty) {
      _cachedRules = [];
      return [];
    }

    try {
      _cachedRules = rulesJson
          .map((ruleStr) => Rule.fromMap(jsonDecode(ruleStr)))
          .toList();
      return _cachedRules!;
    } catch (e) {
      print('Error loading rules: $e');
      _cachedRules = [];
      return [];
    }
  }

  // Save all rules
  Future<bool> saveRules(List<Rule> rules) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert rules to JSON strings
      final rulesJson = rules
          .map((rule) => jsonEncode(rule.toMap()))
          .toList();

      // Update cache
      _cachedRules = List.from(rules);

      // Save to SharedPreferences
      return await prefs.setStringList(_rulesKey, rulesJson);
    } catch (e) {
      print('Error saving rules: $e');
      return false;
    }
  }

  // Add a new rule
  Future<bool> addRule(Rule rule) async {
    final rules = await getRules();
    rules.add(rule);
    return saveRules(rules);
  }

  // Update an existing rule by name
  Future<bool> updateRule(String ruleName, Rule updatedRule) async {
    final rules = await getRules();
    final index = rules.indexWhere((r) => r.name == ruleName);

    if (index == -1) {
      return false;
    }

    rules[index] = updatedRule;
    return saveRules(rules);
  }

  // Delete a rule by name
  Future<bool> deleteRule(String ruleName) async {
    final rules = await getRules();
    final initialLength = rules.length;

    rules.removeWhere((rule) => rule.name == ruleName);

    if (rules.length == initialLength) {
      // No rule was removed
      return false;
    }

    return saveRules(rules);
  }

  // Check if a rule exists by name
  Future<bool> ruleExists(String ruleName) async {
    final rules = await getRules();
    return rules.any((rule) => rule.name == ruleName);
  }

  // Get a single rule by name
  Future<Rule?> getRuleByName(String ruleName) async {
    final rules = await getRules();
    try {
      return rules.firstWhere((rule) => rule.name == ruleName);
    } catch (e) {
      return null;
    }
  }

  // Clear the cache (useful when you want to force a reload from disk)
  void clearCache() {
    _cachedRules = null;
  }

  // Clear all rules
  Future<bool> clearAllRules() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedRules = [];
    return await prefs.remove(_rulesKey);
  }
}