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

  // Modified to show ALL installed apps without any filtering
  Future<void> _loadInstalledApps() async {
    try {
      if (_installedApps.isNotEmpty) {
        // Apps already loaded, no need to fetch again
        setState(() {
          _isLoadingApps = false;
        });
        print("Using cached list of ${_installedApps.length} apps");
        return;
      }
      
      setState(() {
        _isLoadingApps = true;
        _appLoadError = null;
      });
      
      print("Fetching ALL installed apps, including system apps...");
      
      // Force includeSystemApps=true to get ALL apps on the device
      List<AppInfo> apps = await InstalledApps.getInstalledApps(
        true, // INCLUDE system apps
        true, // include app icons
        "",   // no filter
      ).timeout(
        Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Timed out while loading apps. Please try again.");
        },
      );
      
      print("Fetched ${apps.length} total apps from device");
      
      // Sort apps alphabetically by name
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      // No filtering of apps - show everything
      setState(() {
        _installedApps = apps;
        _isLoadingApps = false;
      });
      
      print("Successfully loaded ${apps.length} apps for selection");
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Text(
                          _isAllDay ? 'Every day' : '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
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
                            SizedBox(height: 12),
                            Text(
                              'Set time range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
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
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey.shade50,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 20, color: Colors.black87),
                                              SizedBox(width: 8),
                                              Text(
                                                _formatTimeOfDay(_startTime),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  color: Colors.black,
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
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.grey.shade50,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.access_time, size: 20, color: Colors.black87),
                                              SizedBox(width: 8),
                                              Text(
                                                _formatTimeOfDay(_endTime),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  color: Colors.black,
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

  // Enhanced time picker with better visuals
  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    final String timeTypeLabel = isStartTime ? "Start Time" : "End Time";
    
    try {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: "SELECT $timeTypeLabel",
        confirmText: "SET TIME",
        cancelText: "CANCEL",
        hourLabelText: "Hour",
        minuteLabelText: "Minute",
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.black,
                onPrimary: Colors.white,
                onSurface: Colors.black,
                surface: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Update the state with the new time
        setState(() {
          if (isStartTime) {
            _startTime = pickedTime;
          } else {
            _endTime = pickedTime;
          }
        });
        
        // Schedule another rebuild after the current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // This empty setState forces a UI refresh
            });
          }
        });
      }
    } catch (e) {
      print("Error selecting time: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting time: $e')),
      );
    }
  }

  // Improved time formatting to make sure it always displays correctly
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showAppSelectionBottomSheet(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    List<AppInfo> filteredApps = List.from(_installedApps);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void filterApps(String query) {
              setModalState(() {
                if (query.isEmpty) {
                  filteredApps = List.from(_installedApps);
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
                              Navigator.pop(context);
                              Future.delayed(Duration(milliseconds: 300), () {
                                _showAppSelectionBottomSheet(context);
                              });
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
                                setModalState(() {
                                  if (value == true) {
                                    _selectedApps.add(app.packageName);
                                    print("Added app to block list: ${app.name} (${app.packageName})");
                                  } else {
                                    _selectedApps.remove(app.packageName);
                                    print("Removed app from block list: ${app.name} (${app.packageName})");
                                  }
                                });
                                // Update parent state too
                                setState(() {});
                              },
                              activeColor: Colors.black,
                            ),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  _selectedApps.remove(app.packageName);
                                  print("Removed app from block list: ${app.name} (${app.packageName})");
                                } else {
                                  _selectedApps.add(app.packageName);
                                  print("Added app to block list: ${app.name} (${app.packageName})");
                                }
                              });
                              // Update parent state too
                              setState(() {});
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
                            setModalState(() {
                              _selectedApps.clear();
                            });
                            // Update parent state too
                            setState(() {});
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

    // Enhanced debug prints with very clear formatting
    print("\n");
    print("=====================================================");
    print("                  NEW RULE CREATED                  ");
    print("=====================================================");
    print("Rule Name: ${newRule.name}");
    print("-----------------------------------------------------");
    print("BLOCKED APPS (${newRule.blockedApps.length}):");
    for (int i = 0; i < newRule.blockedApps.length; i++) {
      String appName = "Unknown";
      for (var app in _installedApps) {
        if (app.packageName == newRule.blockedApps[i]) {
          appName = app.name;
          break;
        }
      }
      print("${i+1}. $appName (${newRule.blockedApps[i]})");
    }
    print("-----------------------------------------------------");
    print("Schedule: ${newRule.isAllDay ? 'All day' : '${_formatTimeOfDay(newRule.startTime!)} - ${_formatTimeOfDay(newRule.endTime!)}'}");
    print("Active days: ${newRule.applicableDays.map((d) => d.toString().split('.').last).join(', ')}");
    print("Strict mode: ${newRule.isStrict ? 'YES' : 'NO'}");
    print("=====================================================\n");

    Navigator.pop(context, newRule);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
} 