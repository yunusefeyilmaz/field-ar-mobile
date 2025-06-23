import 'crop.dart';
import 'multiPolygon.dart';

class Field {
  final String id;
  final String name;
  final MultiPolygon geom;
  final Crop? crop;
  final String? plantedDate;
  final String? harvestedDate;

  Field({
    required this.id,
    required this.name,
    required this.geom,
    this.crop,
    this.plantedDate,
    this.harvestedDate,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] as String,
      name: json['name'] as String,
      geom: MultiPolygon.fromJson(json['geom']),
      plantedDate: json['plantedDate'] as String?,
      harvestedDate: json['harvestedDate'] as String?,
      crop:
          json['crop'] != null
              ? Crop.fromJson(json['crop'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plantedDate': plantedDate,
      'harvestedDate': harvestedDate,
      'geom': geom.toJson(),
      'crop': crop?.toJson(),
    };
  }
}
