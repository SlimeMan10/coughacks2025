import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

const platform = MethodChannel('com.hugh.coughacks/permissions');

// A service class to manage permissions data loading and caching
class PermissionsDataService {
  // Singleton instance
  static final PermissionsDataService _instance = PermissionsDataService._internal();

  // Factory constructor to return the singleton instance
  factory PermissionsDataService() => _instance;

  // Internal constructor for singleton
  PermissionsDataService._internal();

  // Data storage
  Map<String, List<AppInfo>> _permissionsToApps = {};
  Map<String, List<String>> _appToPermissions = {};
  List<Map<String, dynamic>> _permissionCards = [];
  List<AppInfo> _installedApps = [];

  // Loading state
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _loadError;

  // Define callbacks for loading state changes
  final List<Function(bool isLoading)> _loadingListeners = [];
  final List<Function(String error)> _errorListeners = [];
  final List<Function()> _dataLoadedListeners = [];

  // Static list of dangerous permissions
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

  // Getters for cached data
  Map<String, List<AppInfo>> get permissionsToApps => _permissionsToApps;
  Map<String, List<String>> get appToPermissions => _appToPermissions;
  List<Map<String, dynamic>> get permissionCards => _permissionCards;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;
  List<String> get dangerousPermissionsList => dangerousPermissions;

  // Method to start preloading data
  Future<void> preloadData() async {
    if (_isLoading || _isLoaded) return;

    _notifyLoadingStateChanged(true);
    _isLoading = true;

    try {
      await _loadPermissionsData();
      _isLoaded = true;
      _isLoading = false;
      _loadError = null;
      _notifyLoadingStateChanged(false);
      _notifyDataLoaded();
    } catch (e) {
      _isLoading = false;
      _loadError = "Failed to load permissions data: $e";
      _notifyLoadingStateChanged(false);
      _notifyError(_loadError!);
      print("Error preloading permissions data: $e");
    }
  }

  // Method to force reload the data
  Future<void> refreshData() async {
    _isLoaded = false;
    return preloadData();
  }

  // Get app permissions from native code
  Future<List<String>> _getAppPermissions(String packageName) async {
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

  // The core data loading implementation
  Future<void> _loadPermissionsData() async {
    print("🔄 Preloading permissions data...");

    // Temporary storage for data processing
    final Map<String, List<AppInfo>> tempPermissionsToApps = {};
    final Map<String, List<String>> tempAppToPermissions = {};

    try {
      // 1. First, load all installed apps
      print("📱 Loading installed apps...");
      final List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true, "");
      _installedApps = installedApps;

      // 2. Process each app's permissions
      print("🔍 Processing app permissions...");
      for (var app in installedApps) {
        final permissions = await _getAppPermissions(app.packageName);
        final dangerous = permissions.where((p) => dangerousPermissions.contains(p)).toList();

        if (dangerous.isNotEmpty) {
          tempAppToPermissions[app.packageName] = dangerous;
          for (var permission in dangerous) {
            tempPermissionsToApps.putIfAbsent(permission, () => []).add(app);
          }
        }
      }

      // 3. Build permission cards lis
      print("🃏 Building permission cards...");
      final List<Map<String, dynamic>> cards = [];

      for (var permission in dangerousPermissions) {
        List<AppInfo> apps = tempPermissionsToApps[permission] ?? [];
        for (var app in apps) {
          cards.add({
            'app': app,
            'permission': permission,
          });
        }
      }

      // 4. Shuffle cards for variety
      cards.shuffle();

      // 5. Update cached data
      _permissionsToApps = tempPermissionsToApps;
      _appToPermissions = tempAppToPermissions;
      _permissionCards = cards;

      print("✅ Permissions data preloaded successfully with ${cards.length} permission cards");
    } catch (e) {
      print("❌ Error loading permissions data: $e");
      throw e; // Rethrow to be caught by the preload method
    }
  }

  // Methods to register listeners
  void addLoadingListener(Function(bool) listener) {
    _loadingListeners.add(listener);
  }

  void removeLoadingListener(Function(bool) listener) {
    _loadingListeners.remove(listener);
  }

  void addErrorListener(Function(String) listener) {
    _errorListeners.add(listener);
  }

  void removeErrorListener(Function(String) listener) {
    _errorListeners.remove(listener);
  }

  void addDataLoadedListener(Function() listener) {
    _dataLoadedListeners.add(listener);
  }

  void removeDataLoadedListener(Function() listener) {
    _dataLoadedListeners.remove(listener);
  }

  // Notification methods
  void _notifyLoadingStateChanged(bool isLoading) {
    for (var listener in _loadingListeners) {
      listener(isLoading);
    }
  }

  void _notifyError(String error) {
    for (var listener in _errorListeners) {
      listener(error);
    }
  }

  void _notifyDataLoaded() {
    for (var listener in _dataLoadedListeners) {
      listener();
    }
  }
}