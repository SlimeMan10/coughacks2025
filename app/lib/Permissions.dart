import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';
import 'package:swipe_cards/swipe_cards.dart';

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

class _PermissionsTabState extends State<PermissionsTab> with AutomaticKeepAliveClientMixin {
  Map<String, List<AppInfo>> permissionsToApps = {};
  Map<String, List<String>> appToPermissions = {};
  List<Map<String, dynamic>> permissionCards = [];
  List<SwipeItem> swipeItems = [];
  MatchEngine? matchEngine;
  bool _isLoading = false;
  bool _isReviewing = false;

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
    "android.permission.READ_CONTACTS": Colors.purple,
    "android.permission.WRITE_CONTACTS": Colors.purple,
    "android.permission.ACCESS_FINE_LOCATION": Colors.blue,
    "android.permission.ACCESS_COARSE_LOCATION": Colors.blue,
    "android.permission.CAMERA": Colors.red,
    "android.permission.RECORD_AUDIO": Colors.orange,
    "android.permission.READ_SMS": Colors.green,
    "android.permission.SEND_SMS": Colors.green,
    "android.permission.READ_PHONE_STATE": Colors.yellow,
    "android.permission.CALL_PHONE": Colors.yellow,
    "android.permission.READ_EXTERNAL_STORAGE": Colors.cyan,
    "android.permission.WRITE_EXTERNAL_STORAGE": Colors.cyan,
    "android.permission.GET_ACCOUNTS": Colors.pink,
    "android.permission.BODY_SENSORS": Colors.brown,
    "android.permission.READ_CALENDAR": Colors.teal,
    "android.permission.WRITE_CALENDAR": Colors.teal,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPermissionsData();
  }

  Future<void> _loadPermissionsData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true, "");
      final Map<String, List<AppInfo>> tempPermissionsToApps = {};
      final Map<String, List<String>> tempAppToPermissions = {};

      for (var app in installedApps) {
        final permissions = await getAppPermissions(app.packageName);
        final dangerous = permissions.where((p) => dangerousPermissions.contains(p)).toList();
        if (dangerous.isNotEmpty) {
          tempAppToPermissions[app.packageName] = dangerous;
          for (var permission in dangerous) {
            tempPermissionsToApps.putIfAbsent(permission, () => []).add(app);
          }
        }
      }

      permissionCards = [];
      for (var permission in dangerousPermissions) {
        List<AppInfo> apps = tempPermissionsToApps[permission] ?? [];
        for (var app in apps) {
          permissionCards.add({
            'app': app,
            'permission': permission,
          });
        }
      }
      permissionCards.shuffle();

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

      setState(() {
        permissionsToApps = tempPermissionsToApps;
        appToPermissions = tempAppToPermissions;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to load permissions data"),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadPermissionsData,
            ),
          ),
        );
      }
    }
  }

  Widget _buildCardContent(AppInfo app, String permission) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (app.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(app.icon!, width: 100, height: 100),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.android, size: 60, color: Colors.grey),
            ),
          const SizedBox(height: 20),
          Text(
            app.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  permissionIcons[permission],
                  size: 32,
                  color: permissionColors[permission],
                ),
                const SizedBox(width: 12),
                Text(
                  permissionNames[permission] ?? "Unknown",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: permissionColors[permission],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              permissionRisks[permission] ?? "Unknown risk",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Does ${app.name} need this permission?",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Colors.red.withOpacity(0.8), size: 28),
              const SizedBox(width: 8),
              const Text("Swipe Left: Settings", style: TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(width: 24),
              const Text("Swipe Right: Accept", style: TextStyle(color: Colors.green, fontSize: 14)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.green.withOpacity(0.8), size: 28),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Permissions',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isReviewing ? Icons.close : Icons.swipe, color: Colors.black87),
            onPressed: () {
              setState(() => _isReviewing = !_isReviewing);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildStatBadge(
                        count: dangerousPermissions.length,
                        label: "permissions tracked",
                        icon: Icons.shield,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        count: appToPermissions.length,
                        label: "apps monitored",
                        icon: Icons.apps,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isReviewing
                      ? (swipeItems.isEmpty
                          ? _buildEmptyState()
                          : SwipeCards(
                              matchEngine: matchEngine!,
                              itemBuilder: (context, index) => swipeItems[index].content,
                              onStackFinished: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("All permissions reviewed!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() => _isReviewing = false);
                              },
                            ))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: dangerousPermissions.length,
                          itemBuilder: (context, index) => _buildPermissionSection(dangerousPermissions[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatBadge({required int count, required String label, required IconData icon, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
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
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.check_circle, size: 48, color: Colors.green),
          ),
          const SizedBox(height: 16),
          const Text(
            "All Clear!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No permissions to review",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _isReviewing = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Back to Overview", style: TextStyle(color: Colors.white)),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (permissionColors[permission] ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              permissionIcons[permission],
              size: 24,
              color: permissionColors[permission],
            ),
          ),
          title: Text(
            permissionNames[permission] ?? "Unknown",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                hasApps ? "${apps.length} apps ($percentage%)" : "No apps",
                style: TextStyle(
                  color: hasApps ? Colors.red : Colors.green,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      permissionRisks[permission] ?? "Unknown risk",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  hasApps ? _buildAppsList(apps, permission) : _buildSafeMessage(permission),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsList(List<AppInfo> apps, String permission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Apps with Access",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) => _buildAppTile(apps[index], permission),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            setState(() => _isReviewing = true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text("Review All", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAppTile(AppInfo app, String permission) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          app.icon != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(app.icon!, width: 48, height: 48),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.android, size: 28, color: Colors.grey),
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
            icon: Icon(Icons.settings, color: Colors.grey[600]),
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.check_circle, size: 28, color: Colors.green),
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