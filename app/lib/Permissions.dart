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
  bool _isReviewing = false; // To toggle between overview and card view

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
  bool get wantKeepAlive => true; // Preserve state when switching tabs

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

      // Build the list of app-permission pairs
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

      // Create swipe items
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
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadPermissionsData,
            ),
          ),
        );
      }
    }
  }

  Widget _buildCardContent(AppInfo app, String permission) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (app.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(app.icon!, width: 100, height: 100),
            )
          else
            const Icon(Icons.android, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
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
          Icon(
            permissionIcons[permission],
            size: 50,
            color: permissionColors[permission],
          ),
          const SizedBox(height: 12),
          Text(
            "Needs ${permissionNames[permission]}",
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              permissionRisks[permission] ?? "Unknown risk",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Does ${app.name} need this permission?",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Colors.red.withOpacity(0.7)),
              const SizedBox(width: 8),
              const Text("Swipe Left: Settings", style: TextStyle(color: Colors.red)),
              const SizedBox(width: 24),
              const Text("Swipe Right: Accept", style: TextStyle(color: Colors.green)),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.green.withOpacity(0.7)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                // Header with a button to start reviewing
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Permission Insights",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isReviewing = !_isReviewing);
                        },
                        icon: const Icon(Icons.card_membership),
                        label: Text(_isReviewing ? "Back" : "Review Permissions"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isReviewing
                      ? (swipeItems.isEmpty
                          ? const Center(
                              child: Text(
                                "No permissions to review",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            )
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
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.shield, color: Colors.blueAccent, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Monitoring ${dangerousPermissions.length} permissions",
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${permissionsToApps.length} permissions used by apps",
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.apps, color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${appToPermissions.length} apps using dangerous permissions",
                                          style: TextStyle(color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildPermissionSection(dangerousPermissions[index]),
                                childCount: dangerousPermissions.length,
                              ),
                            ),
                          ],
                        ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: permissionColors[permission] ?? Colors.grey,
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: (permissionColors[permission] ?? Colors.grey).withOpacity(0.2),
              child: Icon(
                permissionIcons[permission],
                color: permissionColors[permission] ?? Colors.grey,
              ),
            ),
            title: Text(
              permissionNames[permission] ?? "Unknown",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  hasApps ? "${apps.length} apps ($percentage%)" : "No apps",
                  style: TextStyle(
                    color: hasApps ? Colors.redAccent : Colors.green,
                    fontSize: 12,
                  ),
                ),
                Text(
                  permissionRisks[permission] ?? "Unknown risk",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            collapsedBackgroundColor: const Color(0xFF2D2D2D),
            backgroundColor: const Color(0xFF353535),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: hasApps ? _buildAppsList(apps, permission) : _buildSafeMessage(permission),
              ),
            ],
          ),
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
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey[700]),
          itemBuilder: (context, index) => _buildAppTile(apps[index], permission),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            InstalledApps.openSettings(apps.first.packageName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Review in Settings"),
        ),
      ],
    );
  }

  Widget _buildAppTile(AppInfo app, String permission) {
    final otherPermissions = appToPermissions[app.packageName]!
        .where((p) => p != permission)
        .map((p) => permissionNames[p] ?? p)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF404040),
      ),
      child: ListTile(
        leading: app.icon != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(app.icon!, width: 40, height: 40),
              )
            : const Icon(Icons.android, color: Colors.grey, size: 40),
        title: Text(
          app.name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: otherPermissions.isNotEmpty
            ? Text(
                "Also uses: ${otherPermissions.join(', ')}",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.settings, color: Colors.grey),
          onPressed: () => InstalledApps.openSettings(app.packageName),
        ),
      ),
    );
  }

  Widget _buildSafeMessage(String permission) {
    return Column(
      children: [
        Icon(Icons.shield, size: 48, color: Colors.green.withOpacity(0.8)),
        const SizedBox(height: 12),
        const Text(
          "All Clear!",
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "No apps are using ${permissionNames[permission]}.",
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}