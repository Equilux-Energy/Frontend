import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EnergyConsumptionCard extends StatelessWidget {
  const EnergyConsumptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Energy Consumption',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.bolt, color: Color(0xFF2A0030), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Expanded( // Use Expanded to fill available space
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 23,
                    minY: 0,
                    maxY: 100,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 3,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFF2D2D44),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: const Color(0xFF2D2D44),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 3,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${value.toInt()}h',
                              style: const TextStyle(
                                color: Color(0xFF8787A3),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}kW',
                            style: const TextStyle(
                              color: Color(0xFF8787A3),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xFF2D2D44)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(24, (index) => FlSpot(
                          index.toDouble(),
                          (30 + index * 2 + (index % 3 == 0 ? 15 : 0))
                              .clamp(0, 100) as double,
                        )),
                        isCurved: false,
                        color: const Color(0xFF2A0030),
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2A0030).withOpacity(0.4), 
                              const Color(0xff5e0b8b).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xFF2A0030),
                        getTooltipItems: (spots) => spots.map((spot) =>
                          LineTooltipItem(
                            '${spot.y}kW\nat ${spot.x.toInt()}:00',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last 24 hours',
                style: TextStyle(
                  color: Color(0xFF8787A3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}