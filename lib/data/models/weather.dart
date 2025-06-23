class Weather {
  final Daily daily;

  Weather({required this.daily});

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(daily: Daily.fromJson(json['daily']));
  }
}

class Daily {
  final List<String> time;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;
  final List<double> precipitationSum;
  final List<double> windSpeed10mMax;
  final List<int> relativeHumidity2mMean;

  Daily({
    required this.time,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationSum,
    required this.windSpeed10mMax,
    required this.relativeHumidity2mMean,
  });

  factory Daily.fromJson(Map<String, dynamic> json) {
    return Daily(
      time: List<String>.from(json['time']),
      temperature2mMax: List<double>.from(
        json['temperature_2m_max'].map((x) => x.toDouble()),
      ),
      temperature2mMin: List<double>.from(
        json['temperature_2m_min'].map((x) => x.toDouble()),
      ),
      precipitationSum: List<double>.from(
        json['precipitation_sum'].map((x) => x.toDouble()),
      ),
      windSpeed10mMax: List<double>.from(
        json['wind_speed_10m_max'].map((x) => x.toDouble()),
      ),
      relativeHumidity2mMean: List<int>.from(
        json['relative_humidity_2m_mean'].map((x) => x.toInt()),
      ),
    );
  }
}
