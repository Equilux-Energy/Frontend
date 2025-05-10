import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Services/cognito_service.dart';
import '../Services/theme_provider.dart'; // Adjust import based on your project structure

class LongTermConsumptionChart extends StatefulWidget {
  const LongTermConsumptionChart({Key? key}) : super(key: key);

  @override
  State<LongTermConsumptionChart> createState() => _LongTermConsumptionChartState();
}

class _LongTermConsumptionChartState extends State<LongTermConsumptionChart> {
  bool _isLoading = true;
  String? _error;
  List<FlSpot> _dataPoints = [];
  List<String> _dateLabels = [];
  double _maxY = 20;

  @override
  void initState() {
    super.initState();
    _fetchConsumptionData();
  }

  Future<void> _fetchConsumptionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await CognitoService().getLongTermConsumptionPrediction();
      
      if (data.isEmpty) {
        setState(() {
          _error = "No consumption data available";
          _isLoading = false;
        });
        return;
      }
      
      // Create data points for chart
      final List<FlSpot> spots = [];
      final List<String> labels = [];
      
      // Get today's date to calculate actual dates
      final now = DateTime.now();
      
      int index = 0;
      double highestValue = 0;
      
      // Sort the keys to ensure days are in order
      final sortedKeys = data.keys.toList()
        ..sort((a, b) {
          // Extract day numbers from keys like "Day 1"
          final aMatch = RegExp(r'Day (\d+)').firstMatch(a);
          final bMatch = RegExp(r'Day (\d+)').firstMatch(b);
          
          if (aMatch == null || bMatch == null) return 0;
          
          return int.parse(aMatch.group(1)!) - int.parse(bMatch.group(1)!);
        });
      
      for (final key in sortedKeys) {
        final dayMatch = RegExp(r'Day (\d+)').firstMatch(key);
        if (dayMatch != null) {
          final dayOffset = int.parse(dayMatch.group(1)!) - 1;
          final date = now.add(Duration(days: dayOffset));
          
          spots.add(FlSpot(index.toDouble(), data[key]!));
          labels.add(DateFormat('MMM d').format(date)); // Format like "May 10"
          
          if (data[key]! > highestValue) {
            highestValue = data[key]!;
          }
          
          index++;
        }
      }

      setState(() {
        _dataPoints = spots;
        _dateLabels = labels;
        _maxY = highestValue * 1.2; // Set Y-axis max with some padding
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading consumption data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: themeProvider.cardGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Long-Term Energy Consumption Forecast',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: themeProvider.textColorSecondary),
                  onPressed: _fetchConsumptionData,
                  tooltip: 'Refresh data',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '7-Day Prediction',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.textColorSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: SizedBox(
                  height: 250, // Match chart height
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: SizedBox(
                  height: 250, // Match chart height
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load forecast data',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _fetchConsumptionData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 8, top: 8, bottom: 8),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval: _maxY / 5,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Colors.purple,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${_dateLabels[spot.x.toInt()]}: ${spot.y.toStringAsFixed(1)} kWh',
                                TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _maxY / 5,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  value.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: themeProvider.textColorSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < _dateLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _dateLabels[value.toInt()],
                                    style: TextStyle(
                                      color: themeProvider.textColorSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                          left: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: Colors.purple,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purple.withOpacity(0.15),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.purple.withOpacity(0.3),
                                Colors.purple.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: (_dataPoints.length - 1).toDouble(),
                      minY: 0,
                      maxY: _maxY,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Predicted energy consumption in kWh',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.textColorSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}