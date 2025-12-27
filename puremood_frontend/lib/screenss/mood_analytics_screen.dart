import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/MoodAnalyticsService.dart';

class MoodAnalyticsScreen extends StatefulWidget {
  const MoodAnalyticsScreen({super.key});

  @override
  State<MoodAnalyticsScreen> createState() => _MoodAnalyticsScreenState();
}

class _MoodAnalyticsScreenState extends State<MoodAnalyticsScreen> {
  final MoodAnalyticsService service = MoodAnalyticsService();
  String selectedPeriod = 'weekly';
  Map<String, dynamic>? analytics;
  Map<String, dynamic>? aiResult;
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to the page
    if (mounted) {
      fetchData();
    }
  }

  Future<void> _checkAuthAndFetchData() async {
    final bool isLoggedIn = await service.isLoggedIn();
    if (!isLoggedIn && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    await fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final analyticsData = await service.fetchAnalytics(selectedPeriod);
      final aiData = await service.fetchAI();

      setState(() {
        analytics = analyticsData;
        aiResult = aiData;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });

      if (e.toString().contains('token') || e.toString().contains('auth')) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
      }
    }
  }

  Color getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.amber;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color getMoodColor(double moodValue) {
    if (moodValue >= 4) return Colors.green;
    if (moodValue >= 3) return Colors.blue;
    if (moodValue >= 2) return Colors.orange;
    return Colors.red;
  }

  String getMoodEmoji(double moodValue) {
    if (moodValue >= 4.5) return '😄';
    if (moodValue >= 3.5) return '😊';
    if (moodValue >= 2.5) return '😐';
    if (moodValue >= 1.5) return '😢';
    return '😔';
  }

  Widget _buildMoodChart() {
    final hasData = analytics != null && analytics!['has_data'] == true;

    if (!hasData) {
      return _buildNoDataChart();
    }

    final analyticsData = analytics!['analytics'] ?? analytics;
    final avgMood = double.tryParse(analyticsData['average_mood']?.toString() ?? '0') ?? 0.0;

    if (avgMood == 0.0 && selectedPeriod != 'weekly') {
      return _buildPeriodNotAvailableChart();
    }

    // Split data into multiple weeks
    List<List<Map<String, dynamic>>> weeklyCharts = _generateMultipleWeeklyCharts(analyticsData);

    return Column(
      children: weeklyCharts.asMap().entries.map((entry) {
        int weekNumber = entry.key + 1;
        List<Map<String, dynamic>> chartData = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSingleWeekChart(chartData, weekNumber),
        );
      }).toList(),
    );
  }

  Widget _buildSingleWeekChart(List<Map<String, dynamic>> chartData, int weekNumber) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedPeriod == 'weekly' ? 'Week $weekNumber' : 
                        'Month $weekNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedPeriod == 'weekly' ? 'Weekly Trends' : 
                        'Monthly View',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004D40),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    chartData[value.toInt()]['label'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    chartData[value.toInt()]['emoji'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() <= 5) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.teal.shade600,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${chartData[groupIndex]['label']}: ${rod.toY.toStringAsFixed(1)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  barGroups: chartData.asMap().entries.map((entry) {
                    final moodValue = entry.value['mood'].toDouble();
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: moodValue,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                          color: getMoodColor(moodValue),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 5,
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildColorLegend(),
          ],
        ),
      ),
    );
  }

  // Function to split data into multiple periods by type (Daily, Weekly, Monthly)
  List<List<Map<String, dynamic>>> _generateMultipleWeeklyCharts(Map<String, dynamic> analyticsData) {
    List<List<Map<String, dynamic>>> periods = [];
    final entries = analyticsData['entries'] as List<dynamic>? ?? [];
    
    if (selectedPeriod == 'weekly') {
      if (entries.isEmpty) {
        return [_getEmptyWeeklyData()];
      }
      
      List<dynamic> sortedEntries = List.from(entries);
      sortedEntries.sort((a, b) {
        final dateA = DateTime.parse(a['date']).toLocal();
        final dateB = DateTime.parse(b['date']).toLocal();
        return dateA.compareTo(dateB);
      });

      List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      int totalEntries = sortedEntries.length;
      int numberOfWeeks = (totalEntries / 7).ceil();

      for (int week = 0; week < numberOfWeeks; week++) {
        int startIdx = week * 7;
        if (startIdx >= totalEntries) break;

        int endIdx = startIdx + 7;
        if (endIdx > totalEntries) endIdx = totalEntries;

        List<Map<String, dynamic>> weekData = [];

        for (int i = startIdx; i < endIdx; i++) {
          var entry = sortedEntries[i];
          final date = DateTime.parse(entry['date']).toLocal();
          final dayName = allDays[(date.weekday - 1) % 7];

          weekData.add({
            'label': '$dayName ${date.day}',
            'mood': (entry['mood_value'] ?? 3).toDouble(),
            'emoji': entry['mood_emoji'] ?? '😐',
          });
        }

        periods.add(weekData);
      }
    }
    else if (selectedPeriod == 'monthly') {
      // Monthly: Show by weeks (only if we have 7+ days)
      if (entries.isEmpty) {
        return [_getEmptyMonthlyData()];
      }
      
      int totalEntries = entries.length;
      if (totalEntries < 7) {
        // Not enough data for monthly view
        return [_getEmptyMonthlyData()];
      }
      
      // Group into weeks
      int numberOfWeeks = (totalEntries / 7).ceil();
      if (numberOfWeeks > 4) numberOfWeeks = 4; // Max 4 weeks
      
      List<Map<String, dynamic>> monthData = [];
      for (int week = 0; week < numberOfWeeks; week++) {
        int startIdx = week * 7;
        int endIdx = startIdx + 7;
        if (endIdx > totalEntries) endIdx = totalEntries;
        
        // Calculate average mood for this week
        double weekAvg = 0;
        String weekEmoji = '😐';
        int weekCount = 0;
        
        for (int i = startIdx; i < endIdx; i++) {
          weekAvg += (entries[i]['mood_value'] ?? 3).toDouble();
          weekCount++;
        }
        
        if (weekCount > 0) {
          weekAvg = weekAvg / weekCount;
          weekEmoji = getMoodEmoji(weekAvg);
        }
        
        monthData.add({
          'label': 'Week ${week + 1}',
          'mood': double.parse(weekAvg.toStringAsFixed(1)),
          'emoji': weekEmoji,
        });
      }
      
      periods.add(monthData);
    }
    
    return periods;
  }

  List<Map<String, dynamic>> _getEmptyDailyData() {
    return [
      {'label': 'No Data', 'mood': 0.0, 'emoji': '📊'},
    ];
  }

  List<Map<String, dynamic>> _getEmptyWeeklyData() {
    List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => {'label': day, 'mood': 0.0, 'emoji': '📊'}).toList();
  }

  List<Map<String, dynamic>> _getEmptyMonthlyData() {
    return [
      {'label': 'No Data', 'mood': 0.0, 'emoji': '📊'},
      {'label': 'Track 7+ days', 'mood': 0.0, 'emoji': '📈'},
    ];
  }

  List<Map<String, dynamic>> _generateRealisticChartData(Map<String, dynamic> analyticsData) {
    List<Map<String, dynamic>> data = [];

    // Use real data if present
    if (analyticsData['entries'] != null && (analyticsData['entries'] as List).isNotEmpty) {
      final entries = analyticsData['entries'] as List;
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      if (selectedPeriod == 'weekly') {
        // Group entries by the same day
        Map<String, List<Map<String, dynamic>>> groupedByDay = {};
        
        print('📊 [DEBUG] Total entries: ${entries.length}');
        
        for (var entry in entries) {
          final date = DateTime.parse(entry['date']).toLocal();
          final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          print('📊 [DEBUG] Entry date: ${entry['date']} → Local: $date → Key: $dayKey');
          
          if (!groupedByDay.containsKey(dayKey)) {
            groupedByDay[dayKey] = [];
          }
          groupedByDay[dayKey]!.add({
            'date': date,
            'mood_value': double.tryParse(entry['mood_value']?.toString() ?? '3') ?? 3.0,
            'mood_emoji': entry['mood_emoji'],
            'note': entry['note'],
          });
        }
        
        print('📊 [DEBUG] Grouped days: ${groupedByDay.keys.toList()}');
        print('📊 [DEBUG] Number of unique days: ${groupedByDay.length}');
        
        // Create a single point per day (last mood of the day)
        groupedByDay.forEach((dayKey, dayEntries) {
          // Sort by time and take the last entry
          dayEntries.sort((a, b) => a['date'].compareTo(b['date']));
          final lastEntry = dayEntries.last;
          final date = lastEntry['date'] as DateTime;
          final dayName = weekDays[(date.weekday - 1) % 7];
          
          print('📊 [DEBUG] Day: $dayKey → ${dayEntries.length} entries → Last mood: ${lastEntry['mood_emoji']}');
          
          data.add({
            'label': '$dayName ${date.day}',
            'mood': lastEntry['mood_value'],
            'emoji': lastEntry['mood_emoji'] ?? getMoodEmoji(lastEntry['mood_value']),
            'note': lastEntry['note'] ?? '',
            'count': dayEntries.length,
            'fullDate': date, // For correct ordering
          });
        });
        
        // Sort by full date
        data.sort((a, b) {
          final dateA = a['fullDate'] as DateTime;
          final dateB = b['fullDate'] as DateTime;
          return dateA.compareTo(dateB);
        });
        
        print('📊 [DEBUG] Final data points: ${data.length}');
        print('📊 [DEBUG] Labels: ${data.map((d) => d['label']).toList()}');
        
      } else if (selectedPeriod == 'daily') {
        // For daily: show each entry with its time
        for (var entry in entries) {
          final date = DateTime.parse(entry['date']).toLocal();
          final moodValue = double.tryParse(entry['mood_value']?.toString() ?? '3') ?? 3.0;
          
          data.add({
            'label': '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            'mood': moodValue,
            'emoji': entry['mood_emoji'] ?? getMoodEmoji(moodValue),
            'note': entry['note'] ?? '',
          });
        }
      }
      
      return data;
    }

    // Fallback: mock data when there are no entries
    final avgMood = double.tryParse(analyticsData['average_mood']?.toString() ?? '0') ?? 0.0;
    final highDays = analyticsData['high_days'] ?? 0;
    final lowDays = analyticsData['low_days'] ?? 0;

    if (selectedPeriod == 'weekly') {
      final now = DateTime.now();
      List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = weekDays[(date.weekday - 1) % 7];
        double dailyMood = avgMood + (i % 2 == 0 ? 0.3 : -0.2);
        
        if (dailyMood < 1) dailyMood = 1.0;
        if (dailyMood > 5) dailyMood = 5.0;

        data.add({
          'label': '$dayName ${date.day}',
          'mood': double.parse(dailyMood.toStringAsFixed(1)),
          'emoji': getMoodEmoji(dailyMood),
        });
      }
    }
    else if (selectedPeriod == 'daily') {
      // Show hours during the current day
      final now = DateTime.now();
      final currentHour = now.hour;
      List<String> times = [];
      
      // Generate hours from start of day to current hour (every 3 hours)
      for (int hour = 0; hour <= currentHour; hour += 3) {
        final timeStr = hour < 12 ? '${hour == 0 ? 12 : hour}AM' : '${hour == 12 ? 12 : hour - 12}PM';
        times.add(timeStr);
      }
      
      if (times.isEmpty) times.add('12AM'); // Ensure at least one time slot
      
      for (int i = 0; i < times.length; i++) {
        double mood = avgMood + (i % 2 == 0 ? 0.5 : -0.3);
        if (mood < 1) mood = 1.0;
        if (mood > 5) mood = 5.0;

        data.add({
          'label': times[i],
          'mood': double.parse(mood.toStringAsFixed(1)),
          'emoji': getMoodEmoji(mood),
        });
      }
    }
    else {
      List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      for (int i = 0; i < months.length; i++) {
        double mood = avgMood + (i % 3 == 0 ? 0.6 : -0.2);
        if (mood < 1) mood = 1.0;
        if (mood > 5) mood = 5.0;

        data.add({
          'label': months[i],
          'mood': double.parse(mood.toStringAsFixed(1)),
          'emoji': getMoodEmoji(mood),
        });
      }
    }

    return data;
  }

  Widget _buildColorLegend() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'Mood Levels',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('😔 Low (1-2)', Colors.red),
              _buildLegendItem('😐 Medium (2-3)', Colors.orange),
              _buildLegendItem('😊 Good (3-4)', Colors.blue),
              _buildLegendItem('😄 High (4-5)', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No Mood Data Available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start tracking your mood to see analytics',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodNotAvailableChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 40, color: Colors.orange.shade400),
            const SizedBox(height: 8),
            Text(
              selectedPeriod == 'daily' ? 'Daily Data Not Available' :
              selectedPeriod == 'monthly' ? 'Monthly Data Not Available' : 'Data Not Available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selectedPeriod == 'daily'
                  ? 'Only weekly analytics are currently available'
                  : 'Historical monthly data is not yet collected',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedPeriod = 'weekly';
                });
                fetchData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('View Weekly Analytics', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodIndicator() {
    final hasData = analytics != null && analytics!['has_data'] == true;

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              'N/A',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final analyticsData = analytics!['analytics'] ?? analytics;
    final avgMood = double.tryParse(analyticsData['average_mood']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getMoodColor(avgMood).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getMoodColor(avgMood)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getMoodEmoji(avgMood),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            avgMood.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: getMoodColor(avgMood),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final hasData = analytics != null && analytics!['has_data'] == true;

    if (!hasData) {
      return _buildNoStatsAvailable();
    }

    final analyticsData = analytics!['analytics'] ?? analytics;
    final avgMood = double.tryParse(analyticsData['average_mood']?.toString() ?? '0') ?? 0.0;
    final highDays = analyticsData['high_days'] ?? 0;
    final lowDays = analyticsData['low_days'] ?? 0;
    final variance = double.tryParse(analyticsData['variance']?.toString() ?? '0') ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Average Mood',
          avgMood.toStringAsFixed(1),
          Icons.emoji_emotions,
          getMoodColor(avgMood),
          getMoodEmoji(avgMood),
        ),
        _buildStatCard(
          'High Days',
          '$highDays',
          Icons.arrow_upward,
          Colors.green,
          '📈',
        ),
        _buildStatCard(
          'Low Days',
          '$lowDays',
          Icons.arrow_downward,
          Colors.red,
          '📉',
        ),
        _buildStatCard(
          'Stability',
          variance.toStringAsFixed(1),
          Icons.analytics,
          Colors.purple,
          '⚖️',
        ),
      ],
    );
  }

  Widget _buildNoStatsAvailable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              'No Analytics Data',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Complete mood entries to see statistics',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String emoji) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 4),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDetails() {
    final hasData = analytics != null && analytics!['has_data'] == true;

    if (!hasData) {
      return _buildNoMoodDetails();
    }

    final analyticsData = analytics!['analytics'] ?? analytics;
    final trend = analyticsData['trend'] ?? 'stable';
    final startDate = analyticsData['start_date'] ?? 'N/A';
    final endDate = analyticsData['end_date'] ?? 'N/A';
    final message = analyticsData['message'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Summary',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (message.isNotEmpty) ...[
              _buildSummaryItem('Status', message),
              const SizedBox(height: 4),
            ],
            _buildSummaryItem('Analysis Period', selectedPeriod.toUpperCase()),
            _buildSummaryItem('Trend', _capitalize(trend)),
            _buildSummaryItem('Date Range', '${_formatDate(startDate)} - ${_formatDate(endDate)}'),
            const SizedBox(height: 4),
            _buildSummaryItem('Data Available', 'Weekly only'),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date == 'N/A') return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(date).toLocal(); // Convert to local time
      final List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = weekDays[(parsedDate.weekday - 1) % 7];
      final monthName = months[parsedDate.month - 1];
      return '$dayName, $monthName ${parsedDate.day}, ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildSummaryItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMoodDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Details',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_neutral, size: 24, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'No mood entries found',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: Text('Mood Analytics',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: Colors.teal.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: fetchData,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? _buildErrorWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Analysis Period',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildPeriodButton('Weekly', 'weekly'),
                        const SizedBox(width: 12),
                        _buildPeriodButton('Monthly', 'monthly'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildMoodChart(),

            const SizedBox(height: 12),

            _buildStatsGrid(),

            const SizedBox(height: 12),

            _buildMoodDetails(),

            const SizedBox(height: 12),

            _buildAIAnalysisCard(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String text, String period) {
    final bool isSelected = selectedPeriod == period;
    final hasData = analytics != null && analytics!['has_data'] == true;
    final analyticsData = analytics?['analytics'] ?? analytics;
    final avgMood = double.tryParse(analyticsData?['average_mood']?.toString() ?? '0') ?? 0.0;

    final bool dataAvailable = period == 'weekly' || (hasData && avgMood > 0);

    return Expanded(
      child: Tooltip(
        message: !dataAvailable ? 'No data available for $period' : 'View $period analytics',
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedPeriod = period;
            });
            fetchData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.teal : (dataAvailable ? Colors.grey.shade300 : Colors.grey.shade200),
            foregroundColor: isSelected ? Colors.white : (dataAvailable ? Colors.grey.shade700 : Colors.grey.shade500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12)),
              if (!dataAvailable && !isSelected)
                Icon(Icons.info_outline, size: 10, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    final hasAIData = aiResult != null && aiResult!['has_data'] == true;

    final Map<String, dynamic> weeklyPlan =
        (aiResult?['weekly_plan'] as Map<String, dynamic>?) ?? {};
    final List<dynamic> exercises =
        (aiResult?['exercises'] as List<dynamic>?) ?? const [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AI Mood Analysis",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRiskColor(aiResult?['risk_level'] ?? 'low').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: getRiskColor(aiResult?['risk_level'] ?? 'low')),
                  ),
                  child: Text(
                    (aiResult?['risk_level'] ?? 'low').toString().toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: getRiskColor(aiResult?['risk_level'] ?? 'low'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAnalysisItem(
              Icons.message,
              "Analysis",
              hasAIData
                  ? (aiResult?['message'] ?? 'Analyzing your mood patterns...')
                  : 'Start tracking your mood to get AI insights',
            ),
            const SizedBox(height: 8),
            _buildAnalysisItem(
              Icons.lightbulb,
              "Suggestion",
              hasAIData
                  ? (aiResult?['suggestion'] ?? 'Keep tracking your mood for better insights.')
                  : 'Record your mood daily for personalized analysis',
            ),
            if (weeklyPlan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Weekly Plan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildWeeklyPlanList(weeklyPlan),
            ],
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Suggested Exercises',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 8),
              _buildExercisesList(exercises),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPlanList(Map<String, dynamic> weeklyPlan) {
    final dayOrder = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final Map<String, String> dayLabels = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    final items = dayOrder
        .where((key) => weeklyPlan[key] != null && weeklyPlan[key].toString().isNotEmpty)
        .map((key) => MapEntry(key, weeklyPlan[key].toString()))
        .toList();

    if (items.isEmpty) {
      return Text(
        'No weekly plan available yet.',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      );
    }

    return Column(
      children: items.map((entry) {
        final dayKey = entry.key;
        final description = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                alignment: Alignment.topLeft,
                child: Text(
                  dayLabels[dayKey] ?? dayKey,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExercisesList(List<dynamic> exercises) {
    if (exercises.isEmpty) {
      return Text(
        'No exercises available yet.',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      );
    }

    return Column(
      children: exercises.map((e) {
        final text = e.toString();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisItem(IconData icon, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.teal.shade600),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    if (error.contains('404') || error.contains('No analytics data')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Mood Data Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Start tracking your mood to see analytics',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/add-mood');
              },
              icon: Icon(Icons.add_chart, size: 18),
              label: Text('Track Your First Mood', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    else if (error.contains('auth') || error.contains('token') || error.contains('401')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text('Authentication Required',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(error, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Go to Login', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }

    else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text('Error',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(error, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchData,
              child: const Text('Retry', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      );
    }
  }
}