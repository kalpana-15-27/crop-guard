// Data models for CropGuard AI Pests, Detections, and Scan Records
import '../core/date_formatter.dart';

class PestCategory {
  final String id;
  final String pestName;
  final String scientificName;
  final List<String> affectedCrops;
  final String description;
  final String? descriptionTe;
  final String symptoms;
  final String? symptomsTe;
  final String preventiveGuidance;
  final String? preventiveGuidanceTe;

  PestCategory({
    required this.id,
    required this.pestName,
    required this.scientificName,
    required this.affectedCrops,
    required this.description,
    this.descriptionTe,
    required this.symptoms,
    this.symptomsTe,
    required this.preventiveGuidance,
    this.preventiveGuidanceTe,
  });

  factory PestCategory.fromJson(Map<String, dynamic> json) {
    return PestCategory(
      id: json['id'] as String? ?? '',
      pestName: json['pest_name'] as String? ?? 'Unknown Pest',
      scientificName: json['scientific_name'] as String? ?? '',
      affectedCrops: (json['affected_crops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      descriptionTe: json['description_te'] as String?,
      symptoms: json['symptoms'] as String? ?? '',
      symptomsTe: json['symptoms_te'] as String?,
      preventiveGuidance: json['preventive_guidance'] as String? ?? '',
      preventiveGuidanceTe: json['preventive_guidance_te'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pest_name': pestName,
        'scientific_name': scientificName,
        'affected_crops': affectedCrops,
        'description': description,
        'description_te': descriptionTe,
        'symptoms': symptoms,
        'symptoms_te': symptomsTe,
        'preventive_guidance': preventiveGuidance,
        'preventive_guidance_te': preventiveGuidanceTe,
      };
}

class DetectionBox {
  final String pestName;
  final double confidence;
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  DetectionBox({
    required this.pestName,
    required this.confidence,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });

  factory DetectionBox.fromJson(Map<String, dynamic> json) {
    return DetectionBox(
      pestName: json['pest_name'] as String? ?? 'Pest',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      xMin: (json['x_min'] as num?)?.toDouble() ?? 0.0,
      yMin: (json['y_min'] as num?)?.toDouble() ?? 0.0,
      xMax: (json['x_max'] as num?)?.toDouble() ?? 1.0,
      yMax: (json['y_max'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'pest_name': pestName,
        'confidence': confidence,
        'x_min': xMin,
        'y_min': yMin,
        'x_max': xMax,
        'y_max': yMax,
      };
}

class DetectionResult {
  final String id;
  final String? imagePath;
  final String? annotatedImagePath;
  final String cropType;
  final String status; // 'detected', 'no_pest_detected', 'failed'
  final int totalDetections;
  final double processingTimeSec;
  final String modelVersion;
  final PestCategory? primaryPest;
  final double highestConfidence;
  final List<DetectionBox> detections;
  final DateTime createdAt;

  DetectionResult({
    required this.id,
    this.imagePath,
    this.annotatedImagePath,
    required this.cropType,
    required this.status,
    required this.totalDetections,
    required this.processingTimeSec,
    required this.modelVersion,
    this.primaryPest,
    required this.highestConfidence,
    required this.detections,
    required this.createdAt,
  });

  bool get isPestDetected => status == 'detected' && totalDetections > 0;

  factory DetectionResult.fromJson(Map<String, dynamic> json, {String? localImagePath}) {
    final rawImagePath = (json['image_path'] ?? json['image_url']) as String?;
    final rawAnnotatedPath = (json['annotated_image_path'] ?? json['annotated_image_url']) as String?;

    return DetectionResult(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: localImagePath ?? rawImagePath,
      annotatedImagePath: rawAnnotatedPath,
      cropType: json['crop_type'] as String? ?? 'Paddy/Rice',
      status: json['detection_status'] as String? ?? 'pending',
      totalDetections: json['total_detections'] as int? ?? 0,
      processingTimeSec: (json['processing_time_sec'] as num?)?.toDouble() ?? 0.0,
      modelVersion: json['model_version'] as String? ?? 'yolo11s-v1.0',
      primaryPest: json['pest_category'] != null
          ? PestCategory.fromJson(json['pest_category'] as Map<String, dynamic>)
          : null,
      highestConfidence: (json['highest_confidence'] as num?)?.toDouble() ?? 0.0,
      detections: (json['detections'] as List<dynamic>?)
              ?.map((e) => DetectionBox.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: AppDateFormatter.parseUtcToLocal(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_path': imagePath,
        'annotated_image_path': annotatedImagePath,
        'crop_type': cropType,
        'detection_status': status,
        'total_detections': totalDetections,
        'processing_time_sec': processingTimeSec,
        'model_version': modelVersion,
        'pest_category': primaryPest?.toJson(),
        'highest_confidence': highestConfidence,
        'detections': detections.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
