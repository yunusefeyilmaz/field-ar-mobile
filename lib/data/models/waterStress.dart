class WaterStressForecast {
  final List<double> bbox;
  final List<double> centerCoordinates;
  final int predictionDays;
  final Map<String, DailyForecast> dailyForecast;

  WaterStressForecast({
    required this.bbox,
    required this.centerCoordinates,
    required this.predictionDays,
    required this.dailyForecast,
  });

  factory WaterStressForecast.fromJson(Map<String, dynamic> json) {
    final dailyForecastMap = <String, DailyForecast>{};
    if (json['daily_forecast'] != null) {
      json['daily_forecast'].forEach((key, value) {
        dailyForecastMap[key] = DailyForecast.fromJson(value);
      });
    }
    return WaterStressForecast(
      bbox: List<double>.from(json['bbox']),
      centerCoordinates: List<double>.from(json['center_coordinates']),
      predictionDays: json['prediction_days'],
      dailyForecast: dailyForecastMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'bbox': bbox,
    'center_coordinates': centerCoordinates,
    'prediction_days': predictionDays,
    'daily_forecast': dailyForecast.map((k, v) => MapEntry(k, v.toJson())),
  };
}

class DailyForecast {
  final String date;
  final double predictedWaterStress;
  final String stressCategory;

  DailyForecast({
    required this.date,
    required this.predictedWaterStress,
    required this.stressCategory,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
    date: json['date'],
    predictedWaterStress: (json['predicted_water_stress'] as num).toDouble(),
    stressCategory: json['stress_category'],
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'predicted_water_stress': predictedWaterStress,
    'stress_category': stressCategory,
  };
}
