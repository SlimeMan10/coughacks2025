import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareScreenshot {
  final BuildContext context;
  final ScreenshotController screenshotController;

  ShareScreenshot({
    required this.context,
    required this.screenshotController,
  });

  Future<void> captureAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) {
        _showMessage('Screenshot failed to capture.');
        return;
      }

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/screentime.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Check out my screen time!',
      );
    } catch (e) {
      _showMessage('Failed to share screenshot: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
