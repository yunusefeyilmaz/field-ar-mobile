class MultiPolygon {
  final String type;
  final List<List<List<List<double>>>> coordinates;

  MultiPolygon({required this.type, required this.coordinates});

  factory MultiPolygon.fromJson(Map<String, dynamic> json) {
    return MultiPolygon(
      type: json['type'] as String,
      coordinates:
          (json['coordinates'] as List<dynamic>)
              .map(
                (polygon) =>
                    (polygon as List<dynamic>)
                        .map(
                          (ring) =>
                              (ring as List<dynamic>)
                                  .map(
                                    (point) =>
                                        (point as List<dynamic>)
                                            .map(
                                              (coord) =>
                                                  (coord as num).toDouble(),
                                            )
                                            .toList(),
                                  )
                                  .toList(),
                        )
                        .toList(),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'coordinates': coordinates};
  }
}
