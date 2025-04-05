import 'package:flutter/material.dart';

/*
 * ONBOARDING SCREENS DOCUMENTATION
 *
 * This file serves as a reference for all onboarding screens in the app.
 * The implementation is in splash_screen.dart, but this file exists to documen
 * the content, purpose, and flow of each screen for easier management.
 */

class OnboardingConfig {
  // Total number of onboarding screens
  static const int totalScreens = 5;

  // Screen 1: Introduction
  static const Map<String, String> screen1 = {
    'title': 'Screen 1',
    'content': 'First onboarding screen. This will introduce the app concept.',
    'design_notes': 'White background with minimalist design. Black progress indicator at top.'
  };

  // Screen 2: Feature highlight 1
  static const Map<String, String> screen2 = {
    'title': 'Screen 2',
    'content': 'Second onboarding screen. This will highlight a key feature.',
    'design_notes': 'White background with minimalist design. Black progress indicator at top.'
  };

  // Screen 3: Feature highlight 2
  static const Map<String, String> screen3 = {
    'title': 'Screen 3',
    'content': 'Third onboarding screen. This will highlight another key feature.',
    'design_notes': 'White background with minimalist design. Black progress indicator at top.'
  };

  // Screen 4: Feature highlight 3
  static const Map<String, String> screen4 = {
    'title': 'Screen 4',
    'content': 'Fourth onboarding screen. This will highlight the final key feature.',
    'design_notes': 'White background with minimalist design. Black progress indicator at top.'
  };

  // Screen 5: Original splash screen
  static const Map<String, String> screen5 = {
    'title': 'Blockr',
    'content': 'The all-in-one privacy app for your phone!',
    'design_notes': 'Black background with info blocks and Let\'s Go button to request permissions.'
  };
}

/*
 * NAVIGATION LOGIC
 *
 * - Progress indicator at top shows current position (1/5, 2/5, etc.)
 * - Tapping on right half of screen advances to next screen
 * - Tapping on left half of screen returns to previous screen
 * - On first screen, tapping left does nothing
 * - On final screen, tapping right proceeds to permission reques
 * - Swipe gestures also navigate between screens
 */

/*
 * SCREEN LAYOUT
 *
 * ┌────────────────────────────────┐
 * │  ████████░░░░░░░░░░░░░░░░░░░░  │ <- Progress indicator (current position/total)
 * │                                │
 * │                                │
 * │                                │
 * │                                │
 * │            Screen N            │ <- Title
 * │                                │
 * │      Screen description        │ <- Conten
 * │                                │
 * │                                │
 * │                                │
 * │   ┌─────────┐    ┌─────────┐   │
 * │   │ Tap to  │    │ Tap to  │   │ <- Invisible tap areas
 * │   │   go    │    │   go    │   │    (Left half: previous, Right half: next)
 * │   │  back   │    │ forward │   │
 * │   └─────────┘    └─────────┘   │
 * │                                │
 * └────────────────────────────────┘
 */

// The custom onboarding screen widget is defined in splash_screen.dar
// This is the widget used to build screens 1-4:
/*
class OnboardingScreen extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;

  const OnboardingScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.onTapLeft,
    required this.onTapRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Conten
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Left half for going back
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: screenWidth / 2,
          child: GestureDetector(
            onTap: onTapLeft,
            behavior: HitTestBehavior.translucent,
          ),
        ),

        // Right half for going forward
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: screenWidth / 2,
          child: GestureDetector(
            onTap: onTapRight,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
*/