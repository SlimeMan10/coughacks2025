import 'package:app/method_channel.dart';
import 'package:flutter/material.dart';

class RulesPage extends StatefulWidget {
  @override
  _RulesPageState createState() => _RulesPageState();
}

class _RulesPageState extends State<RulesPage> {
  @override
  Widget build(BuildContext context) {


    void onPressed() async {  
      bool enabled = await NativeBridge.isAccessibilityEnabled();
      print("Accessibility enabled: $enabled");
      if (!enabled) {
        await NativeBridge.openAccessibilitySettings(); // if not enabled
      }

     bool overlayGranted = await NativeBridge.hasOverlayPermission();
      if (!overlayGranted) {
        await NativeBridge.requestOverlayPermission();
      } else {
        print("Overlay permission already granted");
        // Maybe trigger your overlay here directly
      }

    }

    return Scaffold(
      body: Center(
          child: Column(
            children: [
              Text("RulesPage screen"),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Set the background color to black
                  foregroundColor: Colors.black, // Optional: set text color to white
                ),
                child: Text("Button press"),
              ),
              Icon(
                Icons.block, // You can replace this with any other icon
                size: 100.0, // You can adjust the size of the icon
                color: Colors.red, // You can customize the icon color
              ),
            ],
          ),
      ),
    );
  }
}