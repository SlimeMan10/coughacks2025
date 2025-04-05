import 'package:app/method_channel.dart'; // Assuming this path is correct
import 'package:flutter/material.dart';

class Blocking extends StatefulWidget {
  final VoidCallback? onPermissionsGranted;

  const Blocking({Key? key, this.onPermissionsGranted}) : super(key: key);

  @override
  _BlockingState createState() => _BlockingState();
}

class _BlockingState extends State<Blocking> {
  bool? _isAccessibilityEnabled;
  bool? _hasOverlayPermission;
  bool _isLoading = true;
  bool _triggeredCallback = false; // New: prevent multiple calls

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Initial check
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
      await Future.delayed(const Duration(milliseconds: 600));
    }

    await _checkPermissions();
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
                label: "Accessibility Service",
                isEnabled: _isAccessibilityEnabled,
              ),
              const SizedBox(height: 15),
              _buildPermissionRow(
                label: "Draw Over Other Apps",
                isEnabled: _hasOverlayPermission,
              ),
              const SizedBox(height: 40),
              if (_isAccessibilityEnabled != true || _hasOverlayPermission != true)
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Grant Permissions"),
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

  Widget _buildPermissionRow({required String label, required bool? isEnabled}) {
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
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            overflow: TextOverflow.ellipsis,
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
