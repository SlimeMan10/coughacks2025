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

class _PermissionsTabState extends State<PermissionsTab> with AutomaticKeepAliveClientMixin {
  Map<String, AppInfo> appMap = {};
  Map<String, List<String>> permissionsMap = {};
  List<String> privacyRisks = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true; // This ensures the state is kept alive

  @override
  void initState() {
    super.initState();
    getAppInfoAndPermissions();
  }

  Future<void> getAppInfoAndPermissions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch installed apps
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        false,
        true,
        "",
      );

      if (installedApps.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = "No installed apps found.";
        });
        return;
      }

      // Fetch permissions for each app
      Map<String, List<String>> tempPermissionsMap = {};
      List<String> tempPrivacyRisks = [];

      for (var app in installedApps) {
        // Store app info
        appMap[app.packageName] = app;

        // Fetch permissions for the app
        List<String> permissions = await getAppPermissions(app.packageName);
        tempPermissionsMap[app.packageName] = permissions;

        // Check for privacy risks (This part can be customized based on your logic)
        // For example, we can assume an app with specific permissions has privacy risks.
        if (permissions.contains("android.permission.READ_CONTACTS") ||
            permissions.contains("android.permission.ACCESS_FINE_LOCATION")) {
          tempPrivacyRisks.add(
            app.packageName,
          ); // Add app to the privacy risks list
        }
      }

      setState(() {
        permissionsMap = tempPermissionsMap;
        privacyRisks = tempPrivacyRisks;
        _isLoading = false;
      });
    } catch (exception) {
      print("Error fetching data: $exception");
      setState(() {
        _isLoading = false;
        _error = "Failed to load data.\nEnsure permissions are granted.";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (permissionsMap.isEmpty) {
      return const Center(
        child: Text(
          'No permission data available.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: appMap.length,
      itemBuilder: (context, index) {
        final app = appMap.values.elementAt(index);
        final permissions = permissionsMap[app.packageName] ?? [];
        final hasRisks = permissions.any((p) => privacyRisks.contains(p));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 2.0,
          color: hasRisks ? Colors.orange[50] : null, // Highlight risky apps
          child: ExpansionTile(
            leading: app.icon != null
                ? Image.memory(app.icon!, width: 40, height: 40)
                : const Icon(Icons.android, size: 40),
            title: Text(
              app.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              hasRisks ? 'Potential Privacy Risks' : 'No major risks detected',
              style: TextStyle(color: hasRisks ? Colors.red : Colors.green),
            ),
            children: permissions.map((perm) {
              final isRisky = privacyRisks.contains(perm);
              return ListTile(
                title: Text(
                  perm,
                  style: TextStyle(color: isRisky ? Colors.red : null),
                ),
                dense: true,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}