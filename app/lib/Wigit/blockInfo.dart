import 'package:flutter/material.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Parent StatefulWidget class
class BlockInfo extends StatefulWidget {
  final String title;
  
  const BlockInfo({Key? key, required this.title}) : super(key: key);
  
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

  List<String> get exemptApps => [..._exemptApps];
  List<bool> get selectedDays => [..._selectedDays];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              title: const Text('Enable Screen Time Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              value: _enableLimits,
              onChanged: (bool value) {
                setState(() {
                  _enableLimits = value;
                });
              },
            ),
            
            const Divider(),
            
            if (_enableLimits) ... [
              const Text('Daily Screen Time Limit', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
              Center(
                child: Text(
                  _formatTimeLimit(_dailyTimeLimit),
                  style: const TextStyle(fontSize: 16)
                )
              ),
            
              const SizedBox(height: 24),
              
              const Text("Downtime (Blocked Hours)", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                title: const Text("Starts"),
                trailing: Text(_startTime.format(context)),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context, 
                    initialTime: _startTime
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _startTime = pickedTime;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text("Ends"),
                trailing: Text(_endTime.format(context)),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context, 
                    initialTime: _endTime
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _endTime = pickedTime;
                    });
                  }
                }
              ),
              
              const SizedBox(height: 24),
              
              const Text('Apply Limits On:', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: _selectedDays,
                onPressed: (int index) {
                  setState(() {
                    _selectedDays[index] = !_selectedDays[index];
                  });
                },
                children: _weekDays.map((day) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(day),
                )).toList(),
              ),
              
              const SizedBox(height: 24),
              
              const Text('Always Allowed Apps', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _showAppSelectionDialog();
                },
                child: const Text('Select Exempt Apps'),
              ),
              
              if (_exemptApps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _exemptApps.map((app) => Chip(
                    label: Text(app),
                    onDeleted: () {
                      setState(() {
                        _exemptApps.remove(app);
                      });
                    },
                  )).toList(),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _saveSettings();
        },
        tooltip: 'Save',
        child: const Icon(Icons.save),
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
        return AlertDialog(
          title: const Text('Select Always Allowed Apps'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableApps.length,
              itemBuilder: (BuildContext context, int index) {
                final String app = availableApps[index];
                final bool isSelected = _exemptApps.contains(app);
                
                return CheckboxListTile(
                  title: Text(app),
                  value: isSelected,
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
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();
    
    // Save all settings
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
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screen time settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}