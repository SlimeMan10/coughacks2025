import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'shareScreenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'tabs.dart';

void main() {
  runApp(const MaterialApp(
    home: AppUsageApp(),
    debugShowCheckedModeBanner: false,
  ));
}

// Infer app category based on package name
String inferCategory(String packageName) {
  packageName = packageName.toLowerCase();
  if (packageName.contains('youtube') || packageName.contains('netflix') || packageName.contains('video') || packageName.contains('music')) {
    return 'Entertainment';
  } else if (packageName.contains('facebook') || packageName.contains('twitter') || packageName.contains('instagram') || packageName.contains('social')) {
    return 'Social';
  } else if (packageName.contains('chrome') || packageName.contains('docs') || packageName.contains('office') || packageName.contains('email')) {
    return 'Productivity';
  } else if (packageName.contains('game') || (packageName.contains('play') && !packageName.contains('google'))) {
    return 'Games';
  } else if (packageName.contains('messenger') || packageName.contains('whatsapp') || packageName.contains('chat')) {
    return 'Communication';
  } else {
    return 'Other';
  }
}

class AppUsageApp extends StatefulWidget {
  const AppUsageApp({super.key});

  @override
  AppUsageAppState createState() => AppUsageAppState();
}

class AppUsageAppState extends State<AppUsageApp>
    with AutomaticKeepAliveClientMixin {
  List<AppUsageInfo> _infos = [];
  Map<String, AppInfo> _appMap = {};
  Map<String, dynamic> _insights = {};
  double _privacyRisk = 0;
  bool _isLoading = false;
  String? _error;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime _endDate = DateTime.now();
  RangeValues _dateRange = const RangeValues(6, 7);

  // Local heuristics for insights
  static const Map<String, double> dataCollectionRates = {
    'Social': 0.01, // KB per second
    'Entertainment': 0.005,
    'Productivity': 0.001,
    'Games': 0.002,
    'Communication': 0.003,
    'Other': 0.0005,
  };

  static const Map<String, List<String>> predictedDataTypes = {
    'Social': ['contacts', 'location', 'interests', 'social graph'],
    'Entertainment': ['viewing habits', 'preferences'],
    'Productivity': ['work-related data', 'productivity patterns'],
    'Games': ['gaming habits', 'in-game purchases'],
    'Communication': ['communication patterns', 'contacts'],
    'Other': ['general usage data'],
  };

  static const Map<String, int> baseRiskScores = {
    'Social': 80,
    'Entertainment': 50,
    'Productivity': 20,
    'Games': 40,
    'Communication': 60,
    'Other': 10,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateDateRange(_dateRange);
  }

  void _updateDateRange(RangeValues range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final start = todayStart.subtract(
      Duration(days: (7 - range.start).floor()),
    );
    final end = todayStart.subtract(Duration(days: (7 - range.end).floor()));
    _startDate = DateTime(start.year, start.month, start.day, 3);
    _endDate = DateTime(end.year, end.month, end.day, now.hour, now.minute, now.second);
    getUsageStatsAndInsights();
  }
   final ScreenshotController _screenshotController = ScreenshotController();


  void _shareScreenshot() {

    ShareScreenshot(
      context: context,
      screenshotController: _screenshotController,
    ).captureAndShare();
  }


  Future<void> getUsageStatsAndInsights() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        _startDate,
        _endDate,
      );
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(
        false,
        true,
        "",
      );
      _appMap = {for (var app in installedApps) app.packageName: app};

      infoList.removeWhere((info) => info.usage.inSeconds <= 0);
      infoList.sort((a, b) => b.usage.compareTo(a.usage));

      Map<String, dynamic> insights = _calculateInsights(infoList);
      double privacyRisk = _calculatePrivacyRisk(infoList, insights);

      setState(() {
        _infos = infoList;
        _insights = insights;
        _privacyRisk = privacyRisk;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to load data: $e";
        _infos = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Map<String, dynamic> _calculateInsights(List<AppUsageInfo> usageInfos) {
    if (usageInfos.isEmpty) {
      return {
        'data_given_out_estimate': {'total_kb': 0, 'by_app': []},
        'predicted_data_types': [],
        'privacy_risk_scores': [],
        'behavioral_insights': [{'text': 'No usage data available.'}],
        'security_tips': [{'text': 'Ensure your device is updated and use strong passwords.'}]
      };
    }

    double totalData = 0;
    List<Map<String, dynamic>> byAppData = [];
    List<Map<String, dynamic>> predictedData = [];
    List<Map<String, dynamic>> riskScores = [];

    for (var info in usageInfos) {
      String category = inferCategory(info.packageName);
      double dataKb = info.usage.inSeconds * (dataCollectionRates[category] ?? 0.001);
      totalData += dataKb;
      byAppData.add({'app_name': info.appName, 'data_kb': dataKb.round()});
      predictedData.add({'app_name': info.appName, 'data_types': predictedDataTypes[category] ?? []});
      int riskScore = (baseRiskScores[category] ?? 50) + (info.usage.inSeconds / 3600).round() * 5;
      riskScore = riskScore.clamp(0, 100);
      riskScores.add({'app_name': info.appName, 'risk_score': riskScore});
    }

    String behavioralInsight = getTotalUsage().inHours > 5
        ? 'High screen time may indicate over-reliance on apps, potentially exposing more data.'
        : 'Your screen time is moderate.';
    String topCategory = usageInfos.isNotEmpty ? inferCategory(usageInfos.first.packageName) : 'Other';
    String securityTip = 'Review privacy settings for $topCategory apps to minimize data sharing.';

    return {
      'data_given_out_estimate': {'total_kb': totalData.round(), 'by_app': byAppData},
      'predicted_data_types': predictedData,
      'privacy_risk_scores': riskScores,
      'behavioral_insights': [{'text': behavioralInsight}],
      'security_tips': [{'text': securityTip}]
    };
  }

  double _calculatePrivacyRisk(List<AppUsageInfo> infos, Map<String, dynamic> insights) {
    if (infos.isEmpty) return 0;
    double totalRisk = 0;
    int totalSeconds = 0;
    for (var info in infos) {
      String appName = info.appName;
      int riskScore = (insights['privacy_risk_scores'] as List<dynamic>).firstWhere(
        (risk) => risk['app_name'] == appName,
        orElse: () => {'risk_score': 50},
      )['risk_score'];
      totalRisk += riskScore * info.usage.inSeconds;
      totalSeconds += info.usage.inSeconds;
    }
    return totalSeconds > 0 ? totalRisk / totalSeconds : 0;
  }

  String formatDuration(Duration duration, {bool forCircle = false}) {
    if (duration.inSeconds < 1) return "< 1m";

    String result = "";
    if (duration.inMinutes >= 1) {
      result = "${duration.inMinutes.remainder(60)}m";
    }
    if (duration.inHours >= 1) {
      result = "${duration.inHours}h $result";
    }
    if (duration.inDays >= 1) {
      result = "${duration.inDays}d $result";
    }

    // If result is empty, at least return 0m
    if (result.isEmpty) {
      result = "0m";
    }

    return result;
  }

  Duration getTotalUsage() {
    return _infos.fold(Duration.zero, (sum, info) => sum + info.usage);
  }

  Map<String, Duration> getCategoryBreakdown() {
    Map<String, Duration> breakdown = {};
    for (var info in _infos) {
      String category = inferCategory(info.packageName);
      breakdown[category] = (breakdown[category] ?? Duration.zero) + info.usage;
    }
    return breakdown;
  }

  Color _getRiskColor(int score) {
    if (score > 75) return Colors.red;
    if (score > 50) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final DateFormat formatter = DateFormat('MMM d, HH:mm');
    final String timeRangeString = "${formatter.format(_startDate)} - ${formatter.format(_endDate)}";

    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'App Usage & Privacy',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.black54),
              onPressed: _shareScreenshot,
            ),
          ],
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScreenTimeSection(timeRangeString),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDataInsightsSection(),
                          const SizedBox(height: 16),
                          _buildAppUsageList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildScreenTimeSection(String timeRangeString) {
    final totalUsage = getTotalUsage();
    final totalDataEstimate = _insights['data_given_out_estimate']?['total_kb'] ?? 0;
    final double usagePercentage = totalUsage.inMinutes / (24 * 60);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular progress indicator
          CircularPercentIndicator(
            radius: 120.0,
            lineWidth: 14.0,
            percent: usagePercentage > 1 ? 1 : usagePercentage,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(totalUsage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Screen Time",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            progressColor: Colors.blue,
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          Text(
            timeRangeString,
            style: const TextStyle(fontSize: 14, color: Colors.black38),
          ),
          const SizedBox(height: 24),

          // Data & Risk metrics
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Data Exposure',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$totalDataEstimate KB',
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Privacy Risk',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_privacyRisk.toStringAsFixed(1)}/100',
                        style: TextStyle(
                          color: _getRiskColor(_privacyRisk.round()),
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Add Review Permissions button - larger with shield icon
          const SizedBox(height: 24),
          Container(
            width: double.infinity, // Make button full width
            child: ElevatedButton.icon(
              onPressed: () {
                // Find closest Scaffold and use it to show a bottom sheet with message
                // Since we can't directly navigate to a specific tab from here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Tap the 'Permissions' tab to review app permissions"),
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'OK',
                      onPressed: () {},
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.shield, // Shield icon
                color: Colors.white,
                size: 28, // Larger icon
              ),
              label: const Text(
                'Review App Permissions',
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Larger text
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // More padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Slightly more rounded
                ),
                elevation: 3, // More elevation
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataInsightsSection() {
    if (_insights.isEmpty) {
      return Container();
    }

    // Get the riskiest app
    final riskScores = _insights['privacy_risk_scores'] as List<dynamic>;
    final riskyApps = [...riskScores];
    riskyApps.sort((a, b) => (b['risk_score'] as int).compareTo(a['risk_score'] as int));
    final riskiestApp = riskyApps.isNotEmpty ? riskyApps.first : null;

    // Get security tip
    final securityTips = _insights['security_tips'] as List<dynamic>;
    final securityTip = securityTips.isNotEmpty ? securityTips.first['text'] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy Insights',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        if (riskiestApp != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_outlined, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Highest Risk App',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      riskiestApp['app_name'],
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRiskColor(riskiestApp['risk_score']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Risk: ${riskiestApp['risk_score']}/100',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(riskiestApp['risk_score']),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (securityTip != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lightbulb_outline, size: 16, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Privacy Tip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  securityTip,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppUsageList() {
    if (_infos.isEmpty) {
      return const Center(
        child: Text(
          'No usage data found.\n(Or permissions needed)',
          style: TextStyle(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Usage & Privacy',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ..._infos.take(6).map((info) => _buildAppUsageTile(info)).toList(),
      ],
    );
  }

  Widget _buildAppUsageTile(AppUsageInfo info) {
    final app = _appMap[info.packageName];
    Widget appIcon = const Icon(Icons.android, size: 36, color: Colors.black54);
    if (app != null && app.icon != null) {
      appIcon = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(app.icon!, width: 36, height: 36),
      );
    }

    final appData = (_insights['data_given_out_estimate']?['by_app'] as List<dynamic>?)?.firstWhere(
          (data) => data['app_name'] == info.appName,
          orElse: () => {'data_kb': 0},
        ) ?? {'data_kb': 0};
    final appRisk = (_insights['privacy_risk_scores'] as List<dynamic>?)?.firstWhere(
          (risk) => risk['app_name'] == info.appName,
          orElse: () => {'risk_score': 0},
        ) ?? {'risk_score': 0};
    final int dataKb = appData['data_kb'] ?? 0;
    final int riskScore = appRisk['risk_score'] ?? 0;
    final String category = inferCategory(info.packageName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            appIcon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.appName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$category • Data: $dataKb KB',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getRiskColor(riskScore),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Risk: $riskScore/100',
                        style: TextStyle(
                          fontSize: 13,
                          color: _getRiskColor(riskScore),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                formatDuration(info.usage),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}