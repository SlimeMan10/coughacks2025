import 'package:app/method_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:app/Rule.dart';
import 'package:app/CreateRulePage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:app/database/ruleDatabase.dart';


class RulesPage extends StatefulWidget {
  @override
  _RulesPageState createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> with SingleTickerProviderStateMixin {
  final RuleStorage _ruleStorage = RuleStorage();
  List<Rule> _rules = [];
  List<Rule> _activeRules = [];
  List<Rule> _inactiveRules = [];
  bool _isLoading = true;
  bool _showActiveSessions = true;
  bool _showInactiveSessions = true;
  
  late AnimationController _animationController;
  late Animation<double> _activeIconRotation;
  late Animation<double> _inactiveIconRotation;

  @override
  void initState() {
    super.initState();
    
    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Set up animations
    _activeIconRotation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _inactiveIconRotation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadRules();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rules = await _ruleStorage.getRules();
      
      // Separate rules into active and inactive
      final now = DateTime.now();
      final currentTimeOfDay = TimeOfDay(hour: now.hour, minute: now.minute);
      final currentDayOfWeek = Rule.getCurrentDayOfWeek();
      
      List<Rule> activeRules = [];
      List<Rule> inactiveRules = [];
      
      for (var rule in rules) {
        if (rule.isActiveNow()) {
          activeRules.add(rule);
        } else {
          inactiveRules.add(rule);
        }
      }
      
      setState(() {
        _rules = rules;
        _activeRules = activeRules;
        _inactiveRules = inactiveRules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleActiveSection() {
    setState(() {
      _showActiveSessions = !_showActiveSessions;
      
      if (_showActiveSessions) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }
  
  void _toggleInactiveSection() {
    setState(() {
      _showInactiveSessions = !_showInactiveSessions;
    });
  }

  @override
  Widget build(BuildContext context) {
    void onPressed() async {  
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateRulePage(),
        ),
      );

      if (result != null && result is Rule) {
        await _ruleStorage.addRule(result);
        _loadRules(); // Reload rules after adding a new one
      }
    }

    // Helper function to format time
    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }
    
    // Build a rule card
    Widget _buildRuleCard(Rule rule) {
      final blockedAppsCount = rule.blockedApps.length;
      final blockedAppsText = rule.blockedApps.contains('All') 
          ? 'All apps blocked' 
          : '$blockedAppsCount app${blockedAppsCount == 1 ? '' : 's'} blocked';
                      
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          rule.isStrict ? Icons.lock : Icons.lock_open,
                          size: 18, 
                          color: Colors.black87
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Edit button
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey),
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateRulePage(ruleToEdit: rule),
                            ),
                          );

                          if (result != null && result is Rule) {
                            await _ruleStorage.updateRule(rule.name, result);
                            _loadRules(); // Reload rules after updating
                          }
                        },
                      ),
                      
                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Rule'),
                                content: Text('Are you sure you want to delete "${rule.name}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('CANCEL'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      'DELETE',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () async {
                                      await _ruleStorage.deleteRule(rule.name);
                                      Navigator.of(context).pop();
                                      _loadRules(); // Reload rules after deleting
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rule.isStrict ? Icons.lock : Icons.lock_open,
                          size: 16,
                          color: rule.isStrict ? Colors.black87 : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rule.isStrict ? 'Blocking (Strict)' : 'Blocking (Normal)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: rule.isStrict ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rule.isAllDay ? Icons.schedule : Icons.access_time,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rule.isAllDay 
                            ? 'All day'
                            : '${formatTimeOfDay(rule.startTime!)} - ${formatTimeOfDay(rule.endTime!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    blockedAppsText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rules',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadRules, // Refresh rules
            icon: Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          heroTag: 'createRuleButton',
          onPressed: onPressed,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 18,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Container(
                  width: 4.5,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 4.0,
          shape: const CircleBorder(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          )
        : _rules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rule_folder_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No rules yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to create your first rule',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                // Active sessions section
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: InkWell(
                    onTap: _toggleActiveSection,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          RotationTransition(
                            turns: _activeIconRotation,
                            child: Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active sessions (${_activeRules.length})',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Active sessions list
                AnimatedCrossFade(
                  firstChild: Column(
                    children: _activeRules.map((rule) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildRuleCard(rule),
                    )).toList(),
                  ),
                  secondChild: SizedBox(height: 0),
                  crossFadeState: _showActiveSessions 
                      ? CrossFadeState.showFirst 
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
                
                // Inactive sessions section
                if (_inactiveRules.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: InkWell(
                      onTap: _toggleInactiveSection,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _showInactiveSessions ? 0 : 0.25,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Inactive sessions (${_inactiveRules.length})',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Inactive sessions list
                  AnimatedCrossFade(
                    firstChild: Column(
                      children: _inactiveRules.map((rule) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildRuleCard(rule),
                      )).toList(),
                    ),
                    secondChild: SizedBox(height: 0),
                    crossFadeState: _showInactiveSessions 
                        ? CrossFadeState.showFirst 
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 300),
                  ),
                ]
              ],
            ),
    );
  }
}