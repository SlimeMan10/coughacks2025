import 'package:flutter/material.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Rule.dart';
import 'database/ruleDatabase.dart';
import 'database/RuleStorageTestUtil.dart';

// Parent StatefulWidget class
class BlockInfo extends StatefulWidget {
  final String title = "Block Info";
  
  const BlockInfo() : super();
  
  @override
  _BlockInfoState createState() => _BlockInfoState();
}

class _BlockInfoState extends State<BlockInfo> {
  // Time limits in minutes
  int _dailyTimeLimit = 120; // 2 hours default
  TimeOfDay _startTime = TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay _endTime = TimeOfDay(hour: 9, minute: 0); // 9:00 AM
  
  // Days of week selection
  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  List<bool> _selectedDays = [true, true, true, true, true, true, true];
  
  // App exceptions list
  List<String> _exemptApps = [];
  
  // Enable/disable flag
  bool _enableLimits = true;

  // Rule database
  final RuleStorage _ruleStorage = RuleStorage();

  List<String> get exemptApps => [..._exemptApps];
  List<bool> get selectedDays => [..._selectedDays];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.purpleAccent,
          secondary: Colors.amber,
          surface: Colors.black,
          background: Colors.black,
        ),
        cardColor: const Color(0xFF121212),
        dividerColor: Colors.grey[800],
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.purpleAccent,
          thumbColor: Colors.amber,
          inactiveTrackColor: Colors.grey[800],
          overlayColor: Colors.purpleAccent.withOpacity(0.2),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.amber;
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.purpleAccent.withOpacity(0.5);
            }
            return Colors.grey[700]!;
          }),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.title),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
                ),
                child: SwitchListTile(
                  title: const Text('Enable Screen Time Limits', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  value: _enableLimits,
                  onChanged: (bool value) {
                    setState(() {
                      _enableLimits = value;
                    });
                  },
                  activeColor: Colors.amber,
                  activeTrackColor: Colors.purpleAccent,
                ),
              ),
              
              if (_enableLimits) ... [
                _buildSectionTitle('Daily Screen Time Limit'),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Slider(
                        value: _dailyTimeLimit.toDouble(),
                        min: 15,
                        max: 480, // 8 hours
                        divisions: 31, // 15-minute intervals
                        label: _formatTimeLimit(_dailyTimeLimit),
                        onChanged: (double value) {
                          setState(() {
                            _dailyTimeLimit = value.round();
                          });
                        }
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _formatTimeLimit(_dailyTimeLimit),
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              
                _buildSectionTitle("Downtime (Blocked Hours)"),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text("Starts"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_startTime.format(context)),
                        ),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context, 
                            initialTime: _startTime,
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.purpleAccent,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF1E1E1E),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _startTime = pickedTime;
                            });
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text("Ends"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_endTime.format(context)),
                        ),
                        onTap: () async {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context, 
                            initialTime: _endTime,
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Colors.purpleAccent,
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF1E1E1E),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _endTime = pickedTime;
                            });
                          }
                        }
                      ),
                    ],
                  ),
                ),
                
                _buildSectionTitle('Apply Limits On:'),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDaySelector(),
                  ),
                ),
                
                _buildSectionTitle('Always Allowed Apps'),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            _showAppSelectionDialog();
                          },
                          label: const Text('Select Exempt Apps'),
                        ),
                        
                        if (_exemptApps.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _exemptApps.map((app) => Chip(
                              backgroundColor: Colors.purple[700],
                              label: Text(app, style: const TextStyle(color: Colors.white)),
                              deleteIconColor: Colors.white,
                              onDeleted: () {
                                setState(() {
                                  _exemptApps.remove(app);
                                });
                              },
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _saveSettings();
          },
          tooltip: 'Save',
          icon: const Icon(Icons.save),
          label: const Text('Save'),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold,
          color: Colors.purpleAccent,
        )
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          return InkWell(
            onTap: () {
              setState(() {
                _selectedDays[index] = !_selectedDays[index];
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purpleAccent,
                  width: 2,
                ),
                color: _selectedDays[index]
                    ? Colors.purpleAccent
                    : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  _weekDays[index],
                  style: TextStyle(
                    color: _selectedDays[index] 
                        ? Colors.white 
                        : Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatTimeLimit(int minutes) {
    if (minutes >= 60) {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours hr${hours > 1 ? 's' : ''} ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  void _showAppSelectionDialog() {
    // Mock list of apps - in a real app, you would fetch installed apps
    final List<String> availableApps = [
      'Instagram', 'TikTok', 'YouTube', 'Facebook', 
      'Twitter', 'Netflix', 'Games', 'Messages'
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData.dark().copyWith(
            dialogBackgroundColor: Colors.black,
            colorScheme: const ColorScheme.dark(
              primary: Colors.purpleAccent,
              secondary: Colors.amber,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.purpleAccent;
                }
                return Colors.grey;
              }),
              checkColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
          child: AlertDialog(
            title: const Text('Select Always Allowed Apps', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableApps.length,
                itemBuilder: (BuildContext context, int index) {
                  final String app = availableApps[index];
                  final bool isSelected = _exemptApps.contains(app);
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.purpleAccent : Colors.grey[700]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: Text(app, style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      activeColor: Colors.purpleAccent,
                      checkColor: Colors.white,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true && !_exemptApps.contains(app)) {
                            _exemptApps.add(app);
                          } else if (value == false && _exemptApps.contains(app)) {
                            _exemptApps.remove(app);
                          }
                        });
                        Navigator.pop(context);
                        _showAppSelectionDialog(); // Reopen dialog with updated selections
                      },
                    ),
                  );
                },
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    // Get SharedPreferences instance for local settings
    final prefs = await SharedPreferences.getInstance();
    
    // Save all settings to SharedPreferences
    await prefs.setInt('dailyTimeLimit', _dailyTimeLimit);
    await prefs.setString('startTimeHour', _startTime.hour.toString());
    await prefs.setString('startTimeMinute', _startTime.minute.toString());
    await prefs.setString('endTimeHour', _endTime.hour.toString());
    await prefs.setString('endTimeMinute', _endTime.minute.toString());
    await prefs.setBool('enableLimits', _enableLimits);
    
    // Save selected days (converting List<bool> to List<String>)
    await prefs.setStringList('selectedDays', 
      _selectedDays.map((day) => day.toString()).toList());
    
    // Save exempt apps
    await prefs.setStringList('exemptApps', _exemptApps);
    
    // Create a new rule with the current settings
    final rule = Rule(
      name: 'screenTimeRule',
      blockedApps: _getAllBlockedApps(),
      isAllDay: false,
      startTime: _startTime,
      endTime: _endTime,
      applicableDays: _getSelectedDaysAsEnum(),
      isStrict: _enableLimits,
    );
    
    // Check if rule exists, then update or add
    bool success = false;
    try {
      if (await _ruleStorage.ruleExists('screenTimeRule')) {
        success = await _ruleStorage.updateRule('screenTimeRule', rule);
      } else {
        success = await _ruleStorage.addRule(rule);
      }
      
      // Run the storage test with the current rule
      if (success) {
        final testResults = await RuleStorageTestUtil.testRuleStorage(rule);
        _showTestResultsDialog(testResults);
      }
    } catch (e) {
      print('Error saving rule: $e');
      success = false;
    }
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success 
          ? 'Screen time settings saved' 
          : 'Error saving settings'),
        duration: const Duration(seconds: 2),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
  
  // Show test results in a dialog
  void _showTestResultsDialog(String results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rule Storage Test Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: Text(
                        results,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<DayOfWeek> _getSelectedDaysAsEnum() {
    List<DayOfWeek> days = [];
    
    if (_selectedDays[0]) days.add(DayOfWeek.Monday);
    if (_selectedDays[1]) days.add(DayOfWeek.Tuesday);
    if (_selectedDays[2]) days.add(DayOfWeek.Wednesday);
    if (_selectedDays[3]) days.add(DayOfWeek.Thursday);
    if (_selectedDays[4]) days.add(DayOfWeek.Friday);
    if (_selectedDays[5]) days.add(DayOfWeek.Saturday);
    if (_selectedDays[6]) days.add(DayOfWeek.Sunday);
    
    return days;
  }
  
  List<String> _getAllBlockedApps() {
    // Mock list of all apps - in a real app, you would fetch installed apps
    final List<String> allApps = [
      'Instagram', 'TikTok', 'YouTube', 'Facebook', 
      'Twitter', 'Netflix', 'Games', 'Messages'
    ];
    
    return allApps.where((app) => !_exemptApps.contains(app)).toList();
  }
}