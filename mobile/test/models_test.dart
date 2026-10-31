import 'package:flutter_test/flutter_test.dart';
import 'package:crop_guard/models/pest_model.dart';

void main() {
  group('Pest & Detection Models Unit Tests', () {
    test('PestCategory serialization and deserialization', () {
      final json = {
        'id': 'pest-123',
        'pest_name': 'Aphids',
        'scientific_name': 'Aphis gossypii',
        'affected_crops': ['Cotton', 'Tomato', 'Chilli'],
        'description': 'Small sap-sucking insect.',
        'description_te': 'చిన్న రసం పీల్చే పురుగు.',
        'symptoms': 'Curled leaves.',
        'symptoms_te': 'ముడుచుకున్న ఆకులు.',
        'preventive_guidance': 'Use yellow sticky traps.',
        'preventive_guidance_te': 'పసుపు అట్టలు వాడండి.',
      };

      final pest = PestCategory.fromJson(json);
      expect(pest.id, equals('pest-123'));
      expect(pest.pestName, equals('Aphids'));
      expect(pest.affectedCrops.length, equals(3));
      expect(pest.descriptionTe, equals('చిన్న రసం పీల్చే పురుగు.'));

      final serialized = pest.toJson();
      expect(serialized['pest_name'], equals('Aphids'));
      expect(serialized['scientific_name'], equals('Aphis gossypii'));
    });

    test('DetectionResult status and detection count logic', () {
      final resultWithPest = DetectionResult(
        id: 'det-1',
        cropType: 'Cotton',
        status: 'detected',
        totalDetections: 4,
        processingTimeSec: 0.18,
        modelVersion: 'yolo11s-v1.0',
        highestConfidence: 0.88,
        detections: [
          DetectionBox(
            pestName: 'Aphids',
            confidence: 0.88,
            xMin: 0.1,
            yMin: 0.1,
            xMax: 0.3,
            yMax: 0.4,
          )
        ],
        createdAt: DateTime.now(),
      );

      expect(resultWithPest.isPestDetected, isTrue);
      expect(resultWithPest.totalDetections, equals(4));

      final cleanResult = DetectionResult(
        id: 'det-2',
        cropType: 'Paddy/Rice',
        status: 'no_pest_detected',
        totalDetections: 0,
        processingTimeSec: 0.15,
        modelVersion: 'yolo11s-v1.0',
        highestConfidence: 0.0,
        detections: [],
        createdAt: DateTime.now(),
      );

      expect(cleanResult.isPestDetected, isFalse);
    });
  });
}
