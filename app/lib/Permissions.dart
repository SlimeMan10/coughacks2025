import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('com.example.app/permissions');

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

class _PermissionsTabState extends State<PermissionsTab> {
  Map<String, List<AppInfo>> permissionsToApps = {};
  Map<String, List<String>> appToPermissions = {};
  int totalApps = 0;
  int permissionsWithApps = 0;
  int appsWithPermissions = 0;
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    _loadPermissionsData();
  }

  Future<void> _loadPermissionsData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Fetch installed apps
      final List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        true,
        true,
        "",
      );
      totalApps = installedApps.length;

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

      setState(() {
        permissionsToApps = tempPermissionsToApps;
        appToPermissions = tempAppToPermissions;
        permissionsWithApps = permissionsToApps.values.where((list) => list.isNotEmpty).length;
        appsWithPermissions = appToPermissions.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load permissions data"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Permission Insights",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.shield, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Monitoring ${dangerousPermissions.length} permissions",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "$permissionsWithApps permissions used by apps",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.apps, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "$appsWithPermissions apps using dangerous permissions",
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
    );
  }

  Widget _buildPermissionSection(String permission) {
    final apps = permissionsToApps[permission] ?? [];
    final hasApps = apps.isNotEmpty;
    final percentage = totalApps > 0 ? (apps.length / totalApps * 100).toStringAsFixed(1) : "0.0";

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