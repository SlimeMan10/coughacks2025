import 'package:flutter/material.dart';
import 'package:app/Rule.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class CreateRulePage extends StatefulWidget {
  @override
  _CreateRulePageState createState() => _CreateRulePageState();
}

class _CreateRulePageState extends State<CreateRulePage> {
  final TextEditingController _nameController = TextEditingController();
  List<String> _selectedApps = [];
  bool _isAllDay = true;
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);
  List<DayOfWeek> _selectedDays = [
    DayOfWeek.Monday,
    DayOfWeek.Tuesday,
    DayOfWeek.Wednesday,
    DayOfWeek.Thursday,
    DayOfWeek.Friday,
    DayOfWeek.Saturday,
    DayOfWeek.Sunday
  ];
  bool _isStrict = false;
  
  // List of installed apps
  List<AppInfo> _installedApps = [];
  bool _isLoadingApps = true;
  String? _appLoadError;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    try {
      setState(() {
        _isLoadingApps = true;
        _appLoadError = null;
      });
      
      List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true, "");
      
      // Sort apps alphabetically by name
      apps.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        _installedApps = apps;
        _isLoadingApps = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingApps = false;
        _appLoadError = "Failed to load installed apps: $e";
      });
      print("Error loading apps: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session name input
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 32, color: Colors.grey.shade500),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Session',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 20,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.edit, color: Colors.grey.shade400),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Help text
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Need help setting up your rule? Tap here.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.blue),
                      onPressed: () {},
                      constraints: BoxConstraints.tightFor(width: 24, height: 24),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Block selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: Icon(Icons.block_outlined),
                  title: Text(
                    'Block',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedApps.isEmpty 
                              ? Colors.amber.shade100 
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedApps.isEmpty 
                                  ? Icons.warning_amber_outlined 
                                  : Icons.check_circle_outline,
                              size: 16, 
                              color: _selectedApps.isEmpty 
                                  ? Colors.amber.shade800 
                                  : Colors.green.shade700
                            ),
                            SizedBox(width: 4),
                            Text(
                              _selectedApps.isEmpty ? 'Select' : '${_selectedApps.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _selectedApps.isEmpty 
                                    ? Colors.amber.shade800 
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedApps.isEmpty 
                                ? 'No apps selected' 
                                : '${_selectedApps.length} app${_selectedApps.length == 1 ? '' : 's'} selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _showAppSelectionBottomSheet(context);
                            },
                            child: Text(
                              _selectedApps.isEmpty ? 'Choose apps to block' : 'Edit selected apps',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                          if (_selectedApps.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedApps.map((packageName) {
                                // Find the app info
                                AppInfo? appInfo;
                                for (var app in _installedApps) {
                                  if (app.packageName == packageName) {
                                    appInfo = app;
                                    break;
                                  }
                                }
                                
                                // Use the available app info or fallback to a generic representation
                                final String appName = appInfo?.name ?? packageName.split('.').last;
                                final Widget appIcon = (appInfo != null && appInfo.icon != null)
                                    ? Image.memory(appInfo.icon!, width: 18, height: 18) 
                                    : Icon(Icons.android, size: 18);
                                
                                return Chip(
                                  label: Text(appName),
                                  avatar: appIcon,
                                  deleteIcon: Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedApps.remove(packageName);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Active time selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: Icon(Icons.access_time),
                  title: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAllDay ? 'Every day' : '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: _isAllDay,
                                onChanged: (value) {
                                  setState(() {
                                    _isAllDay = value;
                                  });
                                },
                                activeColor: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'All day',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Switch(
                                value: _isStrict,
                                onChanged: (value) {
                                  setState(() {
                                    _isStrict = value;
                                  });
                                },
                                activeColor: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Strict',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (!_isAllDay) ...[
                            SizedBox(height: 24),
                            Text(
                              'Set time range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start time',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _selectTime(true),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                                              SizedBox(width: 8),
                                              Text(
                                                _formatTimeOfDay(_startTime),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End time',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      InkWell(
                                        onTap: () => _selectTime(false),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 20, color: Colors.grey.shade600),
                                              SizedBox(width: 8),
                                              Text(
                                                _formatTimeOfDay(_endTime),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Weekdays',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildWeekdaySelector(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 48),

              // Save button
              ElevatedButton(
                onPressed: _createRule,
                child: Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Add to templates button
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Add to templates',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    final weekdays = [
      {'day': DayOfWeek.Monday, 'label': 'M'},
      {'day': DayOfWeek.Tuesday, 'label': 'T'},
      {'day': DayOfWeek.Wednesday, 'label': 'W'},
      {'day': DayOfWeek.Thursday, 'label': 'T'},
      {'day': DayOfWeek.Friday, 'label': 'F'},
      {'day': DayOfWeek.Saturday, 'label': 'S'},
      {'day': DayOfWeek.Sunday, 'label': 'S'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((weekday) {
        final day = weekday['day'] as DayOfWeek;
        final isSelected = _selectedDays.contains(day);
        
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.black : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade400,
                width: 1,
              ),
            ),
            child: Text(
              weekday['label'] as String,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.black,
              onSurface: Colors.black,
            ),
            buttonTheme: ButtonThemeData(
              colorScheme: ColorScheme.light(
                primary: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showAppSelectionBottomSheet(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<AppInfo> filteredApps = _installedApps;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        void filterApps(String query) {
          setState(() {
            if (query.isEmpty) {
              filteredApps = _installedApps;
            } else {
              filteredApps = _installedApps
                  .where((app) => 
                      app.name.toLowerCase().contains(query.toLowerCase()) || 
                      app.packageName.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            }
          });
        }
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Apps to Block',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_selectedApps.length} selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search apps',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            filterApps('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: filterApps,
              ),
              SizedBox(height: 16),
              if (_isLoadingApps)
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                )
              else if (_appLoadError != null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load apps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _appLoadError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _loadInstalledApps();
                        },
                        child: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (filteredApps.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, color: Colors.grey, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'No apps found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isSelected = _selectedApps.contains(app.packageName);
                      
                      return ListTile(
                        leading: app.icon != null
                            ? Image.memory(app.icon!, width: 28, height: 28)
                            : Icon(Icons.android, size: 28),
                        title: Text(
                          app.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedApps.add(app.packageName);
                              } else {
                                _selectedApps.remove(app.packageName);
                              }
                            });
                            // Update parent state
                            this.setState(() {});
                          },
                          activeColor: Colors.black,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedApps.remove(app.packageName);
                            } else {
                              _selectedApps.add(app.packageName);
                            }
                          });
                          // Update parent state
                          this.setState(() {});
                        },
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedApps.clear();
                        });
                        // Update parent state
                        this.setState(() {});
                      },
                      child: Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _createRule() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a session name')),
      );
      return;
    }

    if (_selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one app to block')),
      );
      return;
    }

    if (!_isAllDay && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one day of the week')),
      );
      return;
    }

    final newRule = Rule(
      name: _nameController.text,
      blockedApps: _selectedApps,
      isAllDay: _isAllDay,
      startTime: _isAllDay ? null : _startTime,
      endTime: _isAllDay ? null : _endTime,
      applicableDays: _selectedDays,
      isStrict: _isStrict,
    );

    Navigator.pop(context, newRule);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
} 