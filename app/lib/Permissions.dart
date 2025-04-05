import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:flutter/services.dart'; // For platform channel

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
  @override
  _PermissionsTabState createState() => _PermissionsTabState();
}

class _PermissionsTabState extends State<PermissionsTab> {
  Map<String, List<AppInfo>> permissionsToApps = {}; // Maps permissions to apps
  bool _isLoading = false;
  List<String> dangerousPermissions = [
    "android.permission.READ_CONTACTS",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.CAMERA",
    "android.permission.READ_SMS",
    // Add more dangerous permissions here
  ];
  List<String> dangerousPermissionsNames = [
    "Read Contacts",
    "Access Current Location",
    "Camera",
    "Read Messages",
    // Add more dangerous permissions here
  ];

  @override
  void initState() {
    super.initState();
    getAppInfoAndPermissions();
  }

  Future<void> getAppInfoAndPermissions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch installed apps
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        true,
        true,
        "",
      );

      if (installedApps.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Map to hold permissions and corresponding apps
      Map<String, List<AppInfo>> tempPermissionsToApps = {};

      for (var app in installedApps) {
        // Fetch permissions for the app
        List<String> permissions = await getAppPermissions(app.packageName);

        // Add apps to the permission list
        for (var permission in permissions) {
          if (dangerousPermissions.contains(permission)) {
            if (!tempPermissionsToApps.containsKey(permission)) {
              tempPermissionsToApps[permission] = [];
            }
            tempPermissionsToApps[permission]?.add(app);
          }
        }
      }

      setState(() {
        permissionsToApps = tempPermissionsToApps;
        _isLoading = false;
      });
    } catch (exception) {
      print("Error fetching data: $exception");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load data.\nEnsure permissions are granted.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: dangerousPermissions.length,
      itemBuilder: (context, index) {
        final permission = dangerousPermissions[index];
        final appsWithPermission = permissionsToApps[permission];

        // Check if no apps are using this permission
        final noAppsUsingPermission = appsWithPermission == null || appsWithPermission.isEmpty;
        Icon icon = Icon(Icons.thumb_up, size: 30, color: Colors.green);
        Color color = const Color.fromARGB(255, 207, 245, 209);

        if (!noAppsUsingPermission) {
          icon = Icon(Icons.warning, size: 30, color: Colors.amber);
          color =  const Color.fromARGB(255, 245, 231, 188);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          color: const Color.fromARGB(255, 207, 245, 209),
          elevation: 2.0,
          child: ExpansionTile(
            title: Text(dangerousPermissionsNames[index]),
            leading: icon,
            children: [
              if (noAppsUsingPermission)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thumb_up, size: 50, color: Colors.green),
                      const SizedBox(height: 10),
                      Text(
                        'No apps use this permission!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: appsWithPermission.map((app) {
                    return ListTile(
                      leading: app.icon != null
                          ? Image.memory(app.icon!, width: 40, height: 40)
                          : const Icon(Icons.android, size: 40),
                      title: Text(app.name),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
