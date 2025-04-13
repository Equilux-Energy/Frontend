// chart_card.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'chart_data_service.dart';

class EnergyConsumptionCard extends StatefulWidget {
  const EnergyConsumptionCard({Key? key}) : super(key: key);

  @override
  State<EnergyConsumptionCard> createState() => _EnergyConsumptionCardState();
}

class _EnergyConsumptionCardState extends State<EnergyConsumptionCard> {
  final ChartDataService _dataService = ChartDataService();
  ChartData? _chartData;
  bool _isLoading = true;
  String _selectedPeriod = 'Monthly';

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }
  
  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chartData = await _dataService.loadChartData('energy_consumption');
      setState(() {
        _chartData = chartData;
        _isLoading = false;
      });
      debugPrint('Successfully loaded chart data with ${chartData.data.length} points');
    } catch (e) {
      debugPrint('Error loading chart data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600; // Standard breakpoint for mobile
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A0030).withOpacity(0.7),
              const Color(0xff5e0b8b).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Energy Consumption',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // Use dropdown for mobile, buttons for desktop
                  isMobile
                      ? _buildPeriodDropdown()
                      : Row(
                          children: [
                            _buildPeriodButton('Daily'),
                            const SizedBox(width: 8),
                            _buildPeriodButton('Weekly'),
                            const SizedBox(width: 8),
                            _buildPeriodButton('Monthly'),
                          ],
                        ),
                ],
              ),
              
              // Rest of the widget remains the same
              if (_chartData != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Total: ${_calculateTotal(_chartData!).toStringAsFixed(1)} ${_chartData!.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: _buildChartContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          dropdownColor: const Color(0xFF2A0030),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          items: ['Daily', 'Weekly', 'Monthly'].map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(
                period,
                style: TextStyle(
                  color: _selectedPeriod == period ? Colors.white : Colors.grey,
                  fontWeight: _selectedPeriod == period ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPeriod = newValue;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildChartContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      );
    }
    
    if (_chartData == null) {
      return const Center(
        child: Text(
          'Failed to load chart data',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spots) => const Color(0xFF2A0030).withOpacity(0.8),
            getTooltipItems: (spots) => spots.map((spot) {
              final index = spot.x.toInt();
              final date = _chartData!.data[index].date;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} ${_chartData!.unit}\n${DateFormat('MMM dd').format(date)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          // Bottom titles
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < _chartData!.data.length) {
                  if (index % _getXAxisInterval() == 0) {
                    final date = _chartData!.data[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM dd').format(date),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
          // Left titles
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          // Hide right and top titles
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        minX: 0,
        maxX: _chartData!.data.length - 1.0,
        minY: _chartData!.minValue,
        maxY: _chartData!.maxValue,
        lineBarsData: [
          LineChartBarData(
            spots: _getChartSpots(),
            isCurved: false,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5C005C),
                Color(0xff5e0b8b),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
              getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xff5e0b8b),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF5C005C).withOpacity(0.3),
                  const Color(0xff5e0b8b).withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _getChartSpots() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < _chartData!.data.length; i++) {
      spots.add(FlSpot(i.toDouble(), _chartData!.data[i].value));
    }
    return spots;
  }
  
  int _getXAxisInterval() {
    final length = _chartData!.data.length;
    if (length <= 7) return 1;      // Daily - show each day
    if (length <= 14) return 2;     // Show every other day
    if (length <= 31) return 4;     // Weekly labels for a month
    if (length <= 60) return 7;     // Weekly
    return 10;                      // For longer periods
  }
  
  double _calculateTotal(ChartData data) {
    return data.data.fold(0.0, (sum, point) => sum + point.value);
  }
}