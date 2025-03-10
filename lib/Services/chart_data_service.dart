// chart_data_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' as math;

class ChartDataPoint {
  final DateTime date;
  final double value;
  
  ChartDataPoint({required this.date, required this.value});
  
  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: DateTime.parse(json['date']),
      value: json['value'].toDouble(),
    );
  }
}

class ChartData {
  final List<ChartDataPoint> data;
  final String unit;
  final double minValue;
  final double maxValue;
  
  ChartData({
    required this.data,
    required this.unit,
    required this.minValue,
    required this.maxValue,
  });
  
  factory ChartData.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List)
        .map((item) => ChartDataPoint.fromJson(item))
        .toList();
    
    return ChartData(
      data: dataList,
      unit: json['unit'],
      minValue: json['minValue'].toDouble(),
      maxValue: json['maxValue'].toDouble(),
    );
  }
}

class ChartDataService {
  static final ChartDataService _instance = ChartDataService._internal();
  factory ChartDataService() => _instance;
  ChartDataService._internal();
  
  // Cache for loaded data
  ChartData? _cachedData;
  
  // Instead of trying to load from an asset (which may not be properly included),
  // we'll directly include the JSON as a constant in the code
  Future<ChartData> loadChartData(String chartType) async {
    // Return cached data if available
    if (_cachedData != null) {
      debugPrint('Returning cached chart data');
      return _cachedData!;
    }
    
    try {
      // First try to load from assets
      final path = '${chartType}_chart_data.json';
      debugPrint('Trying to load chart data from: $path');
      
      try {
        final jsonString = await rootBundle.loadString(path);
        final jsonData = json.decode(jsonString);
        _cachedData = ChartData.fromJson(jsonData);
        debugPrint('Successfully loaded chart data from JSON file');
        return _cachedData!;
      } catch (assetError) {
        debugPrint('Failed to load from asset: $assetError');
        // Fall back to embedded JSON
        debugPrint('Using embedded JSON data instead');
        final jsonData = json.decode(_embeddedChartJson);
        _cachedData = ChartData.fromJson(jsonData);
        return _cachedData!;
      }
    } catch (e) {
      debugPrint('Error parsing JSON data: $e');
      // If all else fails, generate random data
      return _generateRandomData();
    }
  }
  
  ChartData _generateRandomData() {
    debugPrint('Generating random chart data');
    final random = math.Random();
    final now = DateTime.now();
    final data = List.generate(
      36,
      (index) => ChartDataPoint(
        date: now.subtract(Duration(days: 36 - index - 1)),
        value: 35 + random.nextDouble() * 20,
      ),
    );
    
    _cachedData = ChartData(
      data: data,
      unit: 'kWh',
      minValue: 30,
      maxValue: 60,
    );
    
    return _cachedData!;
  }
  
  // Embedded JSON data as fallback
  static const String _embeddedChartJson = '''
{
  "data": [
    {"date": "2025-02-01T00:00:00Z", "value": 42.5},
    {"date": "2025-02-02T00:00:00Z", "value": 38.2},
    {"date": "2025-02-03T00:00:00Z", "value": 45.7},
    {"date": "2025-02-04T00:00:00Z", "value": 39.9},
    {"date": "2025-02-05T00:00:00Z", "value": 50.3},
    {"date": "2025-02-06T00:00:00Z", "value": 48.6},
    {"date": "2025-02-07T00:00:00Z", "value": 43.2},
    {"date": "2025-02-08T00:00:00Z", "value": 40.1},
    {"date": "2025-02-09T00:00:00Z", "value": 38.5},
    {"date": "2025-02-10T00:00:00Z", "value": 42.8},
    {"date": "2025-02-11T00:00:00Z", "value": 45.3},
    {"date": "2025-02-12T00:00:00Z", "value": 39.7},
    {"date": "2025-02-13T00:00:00Z", "value": 41.5},
    {"date": "2025-02-14T00:00:00Z", "value": 44.2},
    {"date": "2025-02-15T00:00:00Z", "value": 46.8},
    {"date": "2025-02-16T00:00:00Z", "value": 43.9},
    {"date": "2025-02-17T00:00:00Z", "value": 38.4},
    {"date": "2025-02-18T00:00:00Z", "value": 40.7},
    {"date": "2025-02-19T00:00:00Z", "value": 42.3},
    {"date": "2025-02-20T00:00:00Z", "value": 45.6},
    {"date": "2025-02-21T00:00:00Z", "value": 47.8},
    {"date": "2025-02-22T00:00:00Z", "value": 49.2},
    {"date": "2025-02-23T00:00:00Z", "value": 44.5},
    {"date": "2025-02-24T00:00:00Z", "value": 41.9},
    {"date": "2025-02-25T00:00:00Z", "value": 39.8},
    {"date": "2025-02-26T00:00:00Z", "value": 42.6},
    {"date": "2025-02-27T00:00:00Z", "value": 45.4},
    {"date": "2025-02-28T00:00:00Z", "value": 43.7},
    {"date": "2025-03-01T00:00:00Z", "value": 40.3},
    {"date": "2025-03-02T00:00:00Z", "value": 38.9},
    {"date": "2025-03-03T00:00:00Z", "value": 41.2},
    {"date": "2025-03-04T00:00:00Z", "value": 44.7},
    {"date": "2025-03-05T00:00:00Z", "value": 47.5},
    {"date": "2025-03-06T00:00:00Z", "value": 49.8},
    {"date": "2025-03-07T00:00:00Z", "value": 46.2},
    {"date": "2025-03-08T00:00:00Z", "value": 42.9}
  ],
  "unit": "kWh",
  "minValue": 35.0,
  "maxValue": 55.0
}
''';
}