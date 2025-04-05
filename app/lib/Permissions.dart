import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:app/services/permissions_data_service.dart';

const platform = MethodChannel('com.hugh.coughacks/permissions');

Future<List<String>> getAppPermissions(String packageName) async {
  try {
    final List<dynamic> permissions = await platform.invokeMethod(
      'getPermissions',
      {'packageName': packageName},
    );
    return permissions.cast<String>();
  } catch (e) {
    print("Error fetching permissions for $packageName: $e");
    return [];
  }
}

class PermissionsTab extends StatefulWidget {
  const PermissionsTab({super.key});

  @override
  _PermissionsTabState createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // Use the PermissionsDataService
  final PermissionsDataService _dataService = PermissionsDataService();
  
  Map<String, List<AppInfo>> permissionsToApps = {};
  Map<String, List<String>> appToPermissions = {};
  List<Map<String, dynamic>> permissionCards = [];
  List<SwipeItem> swipeItems = [];
  MatchEngine? matchEngine;
  bool _isLoading = true;
  bool _isReviewing = false; // To toggle between overview and card view
  
  // Animation controllers
  late AnimationController _pageTransitionController;
  late Animation<double> _pageTransitionAnimation;

  static const List<String> dangerousPermissions = [
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.CAMERA",
    "android.permission.RECORD_AUDIO",
    "android.permission.READ_SMS",
    "android.permission.SEND_SMS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.CALL_PHONE",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.GET_ACCOUNTS",
    "android.permission.BODY_SENSORS",
    "android.permission.READ_CALENDAR",
    "android.permission.WRITE_CALENDAR",
  ];

  static const Map<String, String> permissionNames = {
    "android.permission.READ_CONTACTS": "Read Contacts",
    "android.permission.WRITE_CONTACTS": "Modify Contacts",
    "android.permission.ACCESS_FINE_LOCATION": "Precise Location",
    "android.permission.ACCESS_COARSE_LOCATION": "Approximate Location",
    "android.permission.CAMERA": "Camera Access",
    "android.permission.RECORD_AUDIO": "Microphone Access",
    "android.permission.READ_SMS": "Read Messages",
    "android.permission.SEND_SMS": "Send Messages",
    "android.permission.READ_PHONE_STATE": "Phone State",
    "android.permission.CALL_PHONE": "Make Calls",
    "android.permission.READ_EXTERNAL_STORAGE": "Read Storage",
    "android.permission.WRITE_EXTERNAL_STORAGE": "Write Storage",
    "android.permission.GET_ACCOUNTS": "Account Access",
    "android.permission.BODY_SENSORS": "Body Sensors",
    "android.permission.READ_CALENDAR": "Read Calendar",
    "android.permission.WRITE_CALENDAR": "Modify Calendar",
  };

  static const Map<String, String> permissionRisks = {
    "android.permission.READ_CONTACTS": "Apps can see your contact list and personal details.",
    "android.permission.WRITE_CONTACTS": "Apps can edit or delete your contacts.",
    "android.permission.ACCESS_FINE_LOCATION": "Apps can track your exact location.",
    "android.permission.ACCESS_COARSE_LOCATION": "Apps can estimate your general area.",
    "android.permission.CAMERA": "Apps can take photos or videos without notice.",
    "android.permission.RECORD_AUDIO": "Apps can record audio anytime.",
    "android.permission.READ_SMS": "Apps can read your private messages.",
    "android.permission.SEND_SMS": "Apps can send messages (and cost you money).",
    "android.permission.READ_PHONE_STATE": "Apps can see your phone number and call status.",
    "android.permission.CALL_PHONE": "Apps can make calls without your input.",
    "android.permission.READ_EXTERNAL_STORAGE": "Apps can access your files and photos.",
    "android.permission.WRITE_EXTERNAL_STORAGE": "Apps can modify or delete your files.",
    "android.permission.GET_ACCOUNTS": "Apps can see your account details.",
    "android.permission.BODY_SENSORS": "Apps can monitor your health data.",
    "android.permission.READ_CALENDAR": "Apps can view your events and plans.",
    "android.permission.WRITE_CALENDAR": "Apps can change or delete your events.",
  };

  static const Map<String, IconData> permissionIcons = {
    "android.permission.READ_CONTACTS": Icons.contacts,
    "android.permission.WRITE_CONTACTS": Icons.contact_mail,
    "android.permission.ACCESS_FINE_LOCATION": Icons.location_on,
    "android.permission.ACCESS_COARSE_LOCATION": Icons.location_searching,
    "android.permission.CAMERA": Icons.camera_alt,
    "android.permission.RECORD_AUDIO": Icons.mic,
    "android.permission.READ_SMS": Icons.message,
    "android.permission.SEND_SMS": Icons.send,
    "android.permission.READ_PHONE_STATE": Icons.phone_android,
    "android.permission.CALL_PHONE": Icons.call,
    "android.permission.READ_EXTERNAL_STORAGE": Icons.sd_card,
    "android.permission.WRITE_EXTERNAL_STORAGE": Icons.storage,
    "android.permission.GET_ACCOUNTS": Icons.account_circle,
    "android.permission.BODY_SENSORS": Icons.fitness_center,
    "android.permission.READ_CALENDAR": Icons.calendar_today,
    "android.permission.WRITE_CALENDAR": Icons.event,
  };

  static const Map<String, Color> permissionColors = {
    "android.permission.READ_CONTACTS": Colors.black87,
    "android.permission.WRITE_CONTACTS": Colors.black87,
    "android.permission.ACCESS_FINE_LOCATION": Colors.black87,
    "android.permission.ACCESS_COARSE_LOCATION": Colors.black87,
    "android.permission.CAMERA": Colors.black87,
    "android.permission.RECORD_AUDIO": Colors.black87,
    "android.permission.READ_SMS": Colors.black87,
    "android.permission.SEND_SMS": Colors.black87,
    "android.permission.READ_PHONE_STATE": Colors.black87,
    "android.permission.CALL_PHONE": Colors.black87,
    "android.permission.READ_EXTERNAL_STORAGE": Colors.black87,
    "android.permission.WRITE_EXTERNAL_STORAGE": Colors.black87,
    "android.permission.GET_ACCOUNTS": Colors.black87,
    "android.permission.BODY_SENSORS": Colors.black87,
    "android.permission.READ_CALENDAR": Colors.black87,
    "android.permission.WRITE_CALENDAR": Colors.black87,
  };

  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pageTransitionAnimation = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    );
    
    // Set up listeners for the data service
    _dataService.addLoadingListener((isLoading) {
      if (mounted) {
        setState(() {
          _isLoading = isLoading;
        });
      }
    });
    
    _dataService.addDataLoadedListener(() {
      if (mounted) {
        _prepareUIFromCachedData();
      }
    });
    
    _dataService.addErrorListener((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(error);
      }
    });
    
    // Check if data is already loaded or start loading
    if (_dataService.isLoaded) {
      _prepareUIFromCachedData();
    } else {
      _loadPermissionsData();
    }
  }
  
  @override
  void dispose() {
    _pageTransitionController.dispose();
    
    // Clean up listeners
    _dataService.removeLoadingListener((isLoading) {
      if (mounted) {
        setState(() {
          _isLoading = isLoading;
        });
      }
    });
    
    _dataService.removeDataLoadedListener(() {
      if (mounted) {
        _prepareUIFromCachedData();
      }
    });
    
    _dataService.removeErrorListener((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(error);
      }
    });
    
    super.dispose();
  }

  // Prepare UI data from the cached service data
  void _prepareUIFromCachedData() {
    // Get data from service
    permissionsToApps = _dataService.permissionsToApps;
    appToPermissions = _dataService.appToPermissions;
    permissionCards = _dataService.permissionCards;
    
    // Create swipe items
    _createSwipeItems();
    
    // Update UI
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Create SwipeItems from permissionCards
  void _createSwipeItems() {
    swipeItems = permissionCards.map((card) {
      AppInfo app = card['app'];
      String permission = card['permission'];
      return SwipeItem(
        content: _buildCardContent(app, permission),
        likeAction: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Accepted ${app.name} - ${permissionNames[permission]}"),
              backgroundColor: Colors.green,
            ),
          );
        },
        nopeAction: () {
          InstalledApps.openSettings(app.packageName);
        },
      );
    }).toList();

    matchEngine = MatchEngine(swipeItems: swipeItems);
  }
  
  // Show error snackbar
  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to load permissions data"),
        backgroundColor: Colors.redAccent,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadPermissionsData,
        ),
      ),
    );
  }
  
  // Load permissions data through the service
  Future<void> _loadPermissionsData() async {
    setState(() => _isLoading = true);
    
    // Use the data service to load or refresh the data
    if (_dataService.isLoaded) {
      await _dataService.refreshData();
    } else {
      await _dataService.preloadData();
    }
    
    // No need to update state here as it's handled by listeners
  }

  // Toggle review mode with animation
  void _toggleReviewMode(bool value) {
    if (value) {
      setState(() => _isReviewing = true);
      _pageTransitionController.forward();
    } else {
      _pageTransitionController.reverse().then((_) {
        setState(() => _isReviewing = false);
      });
    }
  }

  Widget _buildCardContent(AppInfo app, String permission) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (app.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(app.icon!, width: 80, height: 80),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.android, size: 50, color: Colors.black87),
            ),
          const SizedBox(height: 16),
          Text(
            app.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  permissionIcons[permission],
                  size: 18,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  permissionNames[permission] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            permissionRisks[permission] ?? "Unknown risk",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                onTap: () {
                  InstalledApps.openSettings(app.packageName);
                },
                text: "Settings",
                icon: Icons.settings,
                isNegative: true,
              ),
              _buildActionButton(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Accepted ${app.name} - ${permissionNames[permission]}"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                text: "Allow",
                icon: Icons.check,
                isNegative: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required VoidCallback onTap, 
    required String text, 
    required IconData icon,
    required bool isNegative,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isNegative ? Colors.grey.shade100 : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isNegative ? Colors.grey.shade400 : Colors.black,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isNegative ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isNegative ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Large review button
  Widget _buildReviewButton() {
    return GestureDetector(
      onTap: () => _toggleReviewMode(true),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              "Review Permissions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isReviewing 
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: AnimatedBuilder(
                animation: _pageTransitionAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pageTransitionAnimation.value,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => _toggleReviewMode(false),
                    ),
                  );
                },
              ),
              title: AnimatedBuilder(
                animation: _pageTransitionAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pageTransitionAnimation.value,
                    child: const Text(
                      'Review Permissions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Permissions',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.black),
                  onPressed: _loadPermissionsData,
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Stack(
              children: [
                // Overview content
                AnimatedBuilder(
                  animation: _pageTransitionAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1 - _pageTransitionAnimation.value,
                      child: IgnorePointer(
                        ignoring: _isReviewing,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Review button at the top
                      _buildReviewButton(),
                      
                      // Stats row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildStatBadge(
                              count: _dataService.dangerousPermissionsList.length,
                              label: "permissions tracked",
                              icon: Icons.shield_outlined,
                            ),
                            const SizedBox(width: 12),
                            _buildStatBadge(
                              count: appToPermissions.length,
                              label: "apps with permissions",
                              icon: Icons.apps,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Permission list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _dataService.dangerousPermissionsList.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) => _buildPermissionSection(_dataService.dangerousPermissionsList[index]),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Review cards content
                AnimatedBuilder(
                  animation: _pageTransitionAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pageTransitionAnimation.value,
                      child: IgnorePointer(
                        ignoring: !_isReviewing,
                        child: child,
                      ),
                    );
                  },
                  child: swipeItems.isEmpty
                    ? _buildEmptyState()
                    : SwipeCards(
                        matchEngine: matchEngine!,
                        itemBuilder: (context, index) => swipeItems[index].content,
                        onStackFinished: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("All permissions reviewed!"),
                              backgroundColor: Colors.black,
                            ),
                          );
                          _toggleReviewMode(false);
                        },
                      ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatBadge({required int count, required String label, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.check_circle_outline, size: 40, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          const Text(
            "No permissions to review",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "All your permissions are in order",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _toggleReviewMode(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Back to Overview"),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(String permission) {
    final apps = permissionsToApps[permission] ?? [];
    final hasApps = apps.isNotEmpty;
    final percentage = appToPermissions.isNotEmpty
        ? (apps.length / appToPermissions.length * 100).toStringAsFixed(1)
        : "0.0";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              permissionIcons[permission],
              size: 18, 
              color: Colors.black87
            ),
          ),
          title: Text(
            permissionNames[permission] ?? "Unknown",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                hasApps ? "${apps.length} apps" : "No apps",
                style: TextStyle(
                  color: hasApps ? Colors.red.shade800 : Colors.green.shade800,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      permissionRisks[permission] ?? "Unknown risk",
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  hasApps 
                      ? _buildAppsSimplifiedList(apps, permission) 
                      : _buildSafeMessage(permission),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsSimplifiedList(List<AppInfo> apps, String permission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Apps with Access",
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
          itemBuilder: (context, index) => _buildAppSimplifiedTile(apps[index], permission),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _toggleReviewMode(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text("Review All"),
        ),
      ],
    );
  }

  Widget _buildAppSimplifiedTile(AppInfo app, String permission) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          app.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(app.icon!, width: 40, height: 40),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.android, size: 24, color: Colors.black87),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () => InstalledApps.openSettings(app.packageName),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeMessage(String permission) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.check_circle_outlined, size: 28, color: Colors.green),
        ),
        const SizedBox(height: 12),
        Text(
          "No apps using ${permissionNames[permission]}",
          style: const TextStyle(
            color: Colors.black87, 
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}