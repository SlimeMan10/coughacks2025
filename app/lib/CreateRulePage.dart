import 'package:flutter/material.dart';
import 'package:app/Rule.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:app/database/ruleDatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'database/RuleStorageTestUtil.dart';
import 'dart:async';

class CreateRulePage extends StatefulWidget {
  final Rule? ruleToEdit; // Optional rule for editing

  CreateRulePage({this.ruleToEdit});

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
  bool _isEditMode = false;
  String? _originalRuleName;

  // List of installed apps
  List<AppInfo> _installedApps = [];
  bool _isLoadingApps = true;
  String? _appLoadError;

  // Map to maintain information about hardcoded important apps
  // This allows us to reference these even if they aren't found in scan
  final Map<String, String> _importantApps = {
    'com.google.android.youtube': 'YouTube',
    'com.google.android.gm': 'Gmail',
    'com.google.android.googlequicksearchbox': 'Google',
    'com.android.chrome': 'Chrome'
  };

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();

    // Set up editing mode if a rule is provided
    if (widget.ruleToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final rule = widget.ruleToEdit!;
    _isEditMode = true;
    _originalRuleName = rule.name;

    _nameController.text = rule.name;
    _selectedApps = List.from(rule.blockedApps);
    _isAllDay = rule.isAllDay;

    if (!rule.isAllDay && rule.startTime != null && rule.endTime != null) {
      _startTime = rule.startTime!;
      _endTime = rule.endTime!;
    }

    _selectedDays = List.from(rule.applicableDays);
    _isStrict = rule.isStrict;
  }

  // Modified to only include user apps
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

      print("Fetching installed apps...");

      // Get only user apps, not system apps
      print("Getting user apps...");
      List<AppInfo> userApps = await InstalledApps.getInstalledApps(
        false, // Get user apps only
        true,  // include app icons
        "",    // no filter
      ).timeout(
        Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Timed out while loading user apps");
        },
      );
      
      print("Fetched ${userApps.length} user apps with icons");
      
      // Sort by name for better usability
      userApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      setState(() {
        _installedApps = userApps;
        _isLoadingApps = false;
      });

      print("App list ready with ${userApps.length} user apps");
      
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
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Delete Rule'),
                      content: Text('Are you sure you want to delete "${_nameController.text}"?'),
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
                            if (_originalRuleName != null) {
                              final ruleStorage = RuleStorage();
                              await ruleStorage.deleteRule(_originalRuleName!);
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(context).pop(); // Return to rules page
                            }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  _isEditMode ? 'Edit Rule' : 'Create New Rule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

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
                                // Find app info based on package name
                                AppInfo? appInfo;
                                for (var app in _installedApps) {
                                  if (app.packageName == packageName) {
                                    appInfo = app;
                                    break;
                                  }
                                }

                                // Get a user-friendly app name
                                String appName = "";
                                if (appInfo != null) {
                                  appName = appInfo.name;
                                } else if (_importantApps.containsKey(packageName)) {
                                  appName = _importantApps[packageName]!;
                                } else {
                                  // Get a simplified name without package details
                                  appName = packageName.split('.').last.replaceAll('_', ' ').trim();
                                  // Capitalize first letter for better presentation
                                  if (appName.isNotEmpty) {
                                    appName = appName[0].toUpperCase() + appName.substring(1);
                                  }
                                }

                                return Chip(
                                  label: Text(
                                    appName,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  avatar: appInfo?.icon != null
                                      ? Image.memory(
                                          appInfo!.icon!,
                                          width: 18,
                                          height: 18,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.android, size: 16),
                                  deleteIcon: Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedApps.remove(packageName);
                                      print("Removed from selection: ${appName}");
                                    });
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                                inactiveTrackColor: Colors.grey.shade300,
                                inactiveThumbColor: Colors.white,
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
                                inactiveTrackColor: Colors.grey.shade300,
                                inactiveThumbColor: Colors.white,
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
                  _isEditMode ? 'Update' : 'Schedule',
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

              // Add to templates button - only show in create mode
              if (!_isEditMode)
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Add to templates',
                      style: TextStyle(
                        color: Color(0xFFD0D0D0),
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
    final TextEditingController searchController = TextEditingController();
    List<AppInfo> filteredApps = List.from(_installedApps);

    void filterApps(String query) {
      if (query.isEmpty) {
        filteredApps = List.from(_installedApps);
      } else {
        final lowercaseQuery = query.toLowerCase();
        filteredApps = _installedApps.where((app) {
          final name = app.name.toLowerCase();
          final package = app.packageName.toLowerCase();
          return name.contains(lowercaseQuery) || package.contains(lowercaseQuery);
        }).toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                                setModalState(() {
                                  filterApps('');
                                });
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
                    onChanged: (query) {
                      setModalState(() {
                        filterApps(query);
                      });
                    },
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
                      child: ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Apps',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),

                          // All apps (user apps only, no system apps)
                          ...filteredApps.map((app) {
                            final isSelected = _selectedApps.contains(app.packageName);
                            
                            return ListTile(
                              leading: app.icon != null
                                  ? Image.memory(app.icon!, width: 28, height: 28)
                                  : Icon(Icons.android, size: 28, color: Colors.grey.shade600),
                              title: Text(
                                app.name.isEmpty ? "Unknown App" : app.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value == true) {
                                      _selectedApps.add(app.packageName);
                                      print("Added to block list: ${app.name}");
                                    } else {
                                      _selectedApps.remove(app.packageName);
                                      print("Removed from block list: ${app.name}");
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
                                    print("Removed from block list: ${app.name}");
                                  } else {
                                    _selectedApps.add(app.packageName);
                                    print("Added to block list: ${app.name}");
                                  }
                                });
                                // Update parent state too
                                setState(() {});
                              },
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              dense: true,
                            );
                          }).toList(),
                        ],
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

  // Helper method to get appropriate icon for popular apps
  IconData _getIconForApp(String packageName) {
    switch (packageName) {
      case 'com.google.android.youtube':
        return Icons.play_circle_filled;
      case 'com.google.android.gm':
        return Icons.mail;
      case 'com.google.android.googlequicksearchbox':
        return Icons.search;
      case 'com.android.chrome':
        return Icons.public;
      default:
        return Icons.android;
    }
  }

  Future<void> _createRule() async {
    // Validate inputs
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

    // Create the rule object
    final newRule = Rule(
      name: _nameController.text,
      blockedApps: _selectedApps,
      isAllDay: _isAllDay,
      startTime: _isAllDay ? null : _startTime,
      endTime: _isAllDay ? null : _endTime,
      applicableDays: _selectedDays,
      isStrict: _isStrict,
    );

    // Show a minimal saving indicator via snackbar that doesn't block the UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saving rule...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.grey[800],
      ),
    );

    // Use a separate try/catch block to handle the save operation
    try {
      // Save in background
      final storage = RuleStorage();
      bool success = false;

      // Check if rule exists and update or add accordingly
      if (await storage.ruleExists(newRule.name)) {
        success = await storage.updateRule(newRule.name, newRule);
      } else {
        success = await storage.addRule(newRule);
      }

      // Handle result with appropriate message
      if (success) {
        print("Rule saved successfully: ${newRule.name}");
        
        // Show quick success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rule saved successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen with the new rule
        Navigator.pop(context, newRule);
      } else {
        // Show error without blocking the UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rule'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error saving rule: $e");
      
      // Show error without blocking the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}