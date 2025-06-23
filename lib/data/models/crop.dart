import 'cropModel.dart';

class Crop {
  final String id;
  final String name;
  final CropModel? model;

  Crop({required this.id, required this.name, this.model});

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      name: json['name'] as String,
      model:
          json['model'] != null
              ? CropModel.fromJson(json['model'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ignore: prefer_null_aware_operators
      'model': model != null ? model!.toJson() : null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name; // Consider other fields if necessary

  @override
  int get hashCode => id.hashCode ^ name.hashCode; // Combine hash codes of fields
}
