class CropModel {
  final String id;
  final double? xScale;
  final double? yScale;
  final double? zScale;
  final double? stepSize;
  final String? glbModel;

  CropModel({
    required this.id,
    this.xScale,
    this.yScale,
    this.zScale,
    this.stepSize,
    this.glbModel,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as String,
      xScale: json['xScale'] as double,
      yScale: json['yScale'] as double,
      zScale: json['zScale'] as double,
      stepSize: json['stepSize'] as double,
      glbModel: json['glbModel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'xScale': xScale,
      'yScale': yScale,
      'zScale': zScale,
      'stepSize': stepSize,
      'glbModel': glbModel,
    };
  }
}
