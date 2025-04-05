import 'package:app/method_channel.dart'; // Assuming this path is correc
import 'package:flutter/material.dart';

class Blocking extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;

  const Blocking({Key? key, this.onPermissionsGranted}) : super(key: key);

  @override
  _BlockingState createState() => _BlockingState();
}

class _BlockingState extends State<Blocking> with WidgetsBindingObserver {
  bool? _isAccessibilityEnabled;
  bool? _hasOverlayPermission;
  bool _isLoading = true;
  bool _triggeredCallback = false; // New: prevent multiple calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions(); // Initial check
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (!mounted) return;

    // Show loading indicator only on first load
    if (_isAccessibilityEnabled == null && _hasOverlayPermission == null) {
      setState(() => _isLoading = true);
    }

    bool accessibilityStatus = false;
    bool overlayStatus = false;

    try {
      accessibilityStatus = await NativeBridge.isAccessibilityEnabled();
    } catch (e) {
      print("Error checking accessibility: $e");
    }

    try {
      overlayStatus = await NativeBridge.hasOverlayPermission();
    } catch (e) {
      print("Error checking overlay permission: $e");
    }

    if (!mounted) return;

    setState(() {
      _isAccessibilityEnabled = accessibilityStatus;
      _hasOverlayPermission = overlayStatus;
      _isLoading = false;
    });

    print("Accessibility enabled: $_isAccessibilityEnabled");
    print("Overlay permission granted: $_hasOverlayPermission");

    _maybeTriggerCallback();
  }

  void _maybeTriggerCallback() {
    if (!_triggeredCallback &&
        _isAccessibilityEnabled == true &&
        _hasOverlayPermission == true) {
      _triggeredCallback = true;
      print("✅ Both permissions granted — triggering callback");
      widget.onPermissionsGranted?.call();
    }
  }

  void _requestPermissions() async {
    bool changed = false;

    if (_isAccessibilityEnabled == false) {
      print("Opening accessibility settings...");
      try {
        await NativeBridge.openAccessibilitySettings();
        changed = true;
      } catch (e) {
        print("Error: $e");
      }
    }

    if (changed) await Future.delayed(const Duration(milliseconds: 300));

    if (_hasOverlayPermission == false) {
      print("Requesting overlay permission...");
      try {
        await NativeBridge.requestOverlayPermission();
        changed = true;
      } catch (e) {
        print("Error: $e");
      }
    }

    if (changed) {
      // Schedule a permission check shortly after returning from settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPermissionsWithRetry();
      });
    } else {
      await _checkPermissions();
    }
  }

  // New method to check permissions with retries
  Future<void> _checkPermissionsWithRetry() async {
    // First immediate check
    await _checkPermissions();

    // If not all permissions are granted, set up periodic checks
    if (!(_isAccessibilityEnabled == true && _hasOverlayPermission == true)) {
      // Check permissions again after 1 second
      Future.delayed(const Duration(milliseconds: 800), () async {
        if (!mounted) return;
        await _checkPermissions();

        // If still not granted, check one more time after a shorter delay
        if (!(_isAccessibilityEnabled == true && _hasOverlayPermission == true)) {
          Future.delayed(const Duration(milliseconds: 800), () async {
            if (!mounted) return;
            await _checkPermissions();

            // One final check after another delay if needed
            if (!(_isAccessibilityEnabled == true && _hasOverlayPermission == true)) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (!mounted) return;
                _checkPermissions();
              });
            }
          });
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background (likely returning from settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsWithRetry();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Required Permissions",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                "Please grant all permissions below to use the app.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 30),
              _buildPermissionRow(
                label: "Screen Time Tracking",
                description: "Allows tracking app usage and enforcing limits",
                isEnabled: _isAccessibilityEnabled,
              ),
              const SizedBox(height: 15),
              _buildPermissionRow(
                label: "Display Over Apps",
                description: "Enables blocking notifications when limits are reached",
                isEnabled: _hasOverlayPermission,
              ),
              const SizedBox(height: 40),
              if (_isAccessibilityEnabled != true || _hasOverlayPermission != true)
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: Icon(Icons.security, size: 24),
                  label: Text(
                    "Grant Screen Access",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[400]),
                      const SizedBox(width: 10),
                      Text(
                        "All permissions granted!",
                        style: TextStyle(color: Colors.green[400], fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({required String label, required String description, required bool? isEnabled}) {
    IconData iconData;
    Color iconColor;
    String statusText;

    if (isEnabled == null) {
      iconData = Icons.hourglass_empty;
      iconColor = Colors.grey;
      statusText = "Checking...";
    } else if (isEnabled == true) {
      iconData = Icons.key;
      iconColor = Colors.green[400]!;
      statusText = "Granted";
    } else {
      iconData = Icons.key_off;
      iconColor = Colors.red[400]!;
      statusText = "Required";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Row(
          children: [
            Text(statusText, style: TextStyle(color: iconColor, fontSize: 16)),
            const SizedBox(width: 8),
            if (isEnabled == null)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
              )
            else
              Icon(iconData, color: iconColor, size: 28.0),
          ],
        ),
      ],
    );
  }
}
