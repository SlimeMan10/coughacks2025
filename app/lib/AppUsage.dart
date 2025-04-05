import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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

class AppUsageAppState extends State<AppUsageApp> with AutomaticKeepAliveClientMixin {
  List<AppUsageInfo> _infos = [];
  Map<String, AppInfo> _appMap = {};
  Map<String, dynamic> _insights = {};
  double _overallRisk = 0;
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
    final start = todayStart.subtract(Duration(days: (7 - range.start).floor()));
    final end = todayStart.subtract(Duration(days: (7 - range.end).floor()));
    _startDate = DateTime(start.year, start.month, start.day, 3);
    _endDate = DateTime(end.year, end.month, end.day, now.hour, now.minute, now.second);
    getUsageStatsAndInsights();
  }

  Future<void> getUsageStatsAndInsights() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(_startDate, _endDate);
      List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true, "");
      _appMap = {for (var app in installedApps) app.packageName: app};

      infoList.removeWhere((info) => info.usage.inSeconds <= 0);
      infoList.sort((a, b) => b.usage.compareTo(a.usage));

      Map<String, dynamic> insights = _calculateInsights(infoList);
      double overallRisk = _calculateOverallRisk(infoList, insights);

      setState(() {
        _infos = infoList;
        _insights = insights;
        _overallRisk = overallRisk;
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

  double _calculateOverallRisk(List<AppUsageInfo> infos, Map<String, dynamic> insights) {
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

  String formatDuration(Duration duration) {
    if (duration.inSeconds < 1) return "< 1s";
    String result = "${duration.inSeconds.remainder(60)}s";
    if (duration.inMinutes >= 1) result = "${duration.inMinutes.remainder(60)}m $result";
    if (duration.inHours >= 1) result = "${duration.inHours}h $result";
    if (duration.inDays >= 1) result = "${duration.inDays}d $result";
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF1E1E1E),
            expandedHeight: 400.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(''),
              background: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildInsightsHeader(timeRangeString),
                    _buildDateRangeSlider(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _infos.isEmpty
                          ? const Center(
                              child: Text(
                                'No usage data found.\n(Or permissions needed)',
                                style: TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                const Text(
                                  'App Usage & Privacy',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                ..._infos.map((info) => _buildAppUsageTile(info)).toList(),
                                const SizedBox(height: 20),
                                const Text(
                                  'Privacy Insights',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                _buildInsightsSection(),
                              ],
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
        onPressed: () => _updateDateRange(_dateRange),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildInsightsHeader(String timeRangeString) {
    final totalUsage = getTotalUsage();
    final categoryBreakdown = getCategoryBreakdown();
    final double usagePercentage = totalUsage.inMinutes / (24 * 60);
    final totalDataEstimate = _insights['data_given_out_estimate']?['total_kb'] ?? 0;

    return Column(
      children: [
        const SizedBox(height: 16),
        CircularPercentIndicator(
          radius: 60.0,
          lineWidth: 10.0,
          percent: usagePercentage > 1 ? 1 : usagePercentage,
          center: Text(
            formatDuration(totalUsage),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          progressColor: Colors.blueAccent,
          backgroundColor: Colors.white12,
        ),
        const SizedBox(height: 12),
        Text(
          "Screen Time",
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
        ),
        Text(
          timeRangeString,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
        ),
        const SizedBox(height: 10),
        _buildCategorySummary(categoryBreakdown),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  'Total Data Exposure',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '$totalDataEstimate KB',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  'Overall Risk',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  '${_overallRisk.toStringAsFixed(1)}/100',
                  style: TextStyle(color: _getRiskColor(_overallRisk.round()), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySummary(Map<String, Duration> breakdown) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: breakdown.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${entry.key}: ${formatDuration(entry.value)}",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text('Select Date Range (Last 7 days)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          RangeSlider(
            min: 0,
            max: 7,
            divisions: 7,
            values: _dateRange,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white24,
            labels: RangeLabels(
              "${7 - _dateRange.start.toInt()}d ago",
              _dateRange.end.toInt() == 7 ? "Now" : "${7 - _dateRange.end.toInt()}d ago",
            ),
            onChanged: (values) {
              if ((values.end - values.start) <= 7) {
                setState(() => _dateRange = values);
              }
            },
            onChangeEnd: (values) => _updateDateRange(values),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAppUsageTile(AppUsageInfo info) {
    final app = _appMap[info.packageName];
    Widget appIcon = const Icon(Icons.android, size: 36, color: Colors.white70);
    if (app != null && app.icon != null) {
      appIcon = Image.memory(app.icon!, width: 36, height: 36);
    }

    double usagePercent = info.usage.inSeconds / getTotalUsage().inSeconds;
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

    return Stack(
      children: [
        Container(
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.blueAccent.withOpacity(0.1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usagePercent.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          leading: appIcon,
          title: Text(info.appName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${inferCategory(info.packageName)} • Data: $dataKb KB',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Row(
                children: [
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
                    style: TextStyle(color: _getRiskColor(riskScore), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          trailing: Text(
            formatDuration(info.usage),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    if (_insights.isEmpty) {
      return const Text(
        'No insights available yet.',
        style: TextStyle(color: Colors.white70),
      );
    }

    List<dynamic> predictedData = _insights['predicted_data_types'] ?? [];
    List<dynamic> riskScores = _insights['privacy_risk_scores'] ?? [];
    List<dynamic> behavioralInsights = _insights['behavioral_insights'] ?? [];
    List<dynamic> securityTips = _insights['security_tips'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (predictedData.isNotEmpty) ...[
          Card(
            color: Colors.purple.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      const Text(
                        'What They Might Know',
                        style: TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...predictedData.map((data) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${data['app_name']}: ${data['data_types'].join(', ')}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (riskScores.isNotEmpty) ...[
          Card(
            color: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      const Text(
                        'Privacy Risk Scores',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...riskScores.map((risk) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${risk['app_name']}: ${risk['risk_score']}/100',
                          style: TextStyle(color: _getRiskColor(risk['risk_score']), fontSize: 12),
                        ),
                      )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (behavioralInsights.isNotEmpty) ...[
          Card(
            color: Colors.orange.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      const Text(
                        'Your Habits',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...behavioralInsights.map((insight) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          insight['text'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (securityTips.isNotEmpty) ...[
          Card(
            color: Colors.green.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      const Text(
                        'Stay Secure',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...securityTips.map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          tip['text'],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )).toList(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}