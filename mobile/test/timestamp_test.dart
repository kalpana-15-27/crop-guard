import 'package:flutter_test/flutter_test.dart';
import 'package:crop_guard/core/date_formatter.dart';
import 'package:crop_guard/models/pest_model.dart';

void main() {
  group('UTC to Local Timezone & 24-Hour Format Tests', () {
    test('Converts UTC timestamp (05:04 UTC) to local timezone (10:34 in IST)', () {
      // 05:04 UTC
      const utcIsoString = '2026-11-02T05:04:00Z';
      final localDt = AppDateFormatter.parseUtcToLocal(utcIsoString);

      // Verify that localDt has been converted to local
      expect(localDt.isUtc, isFalse);

      // On an IST (UTC+05:30) machine, 05:04 UTC becomes 10:34 IST
      final localOffset = DateTime.now().timeZoneOffset;
      if (localOffset.inHours == 5 && localOffset.inMinutes == 330) {
        expect(AppDateFormatter.formatTime(localDt), '10:34');
        expect(AppDateFormatter.formatDateTime(localDt), '02 Nov 2026, 10:34');
      }
    });

    test('24-Hour clock format (HH:mm) produces zero-padded double digits without AM/PM', () {
      final dtMidnight = DateTime(2026, 11, 2, 0, 5);
      final dtMorning = DateTime(2026, 11, 2, 9, 30);
      final dtAfternoon = DateTime(2026, 11, 2, 14, 5);
      final dtNight = DateTime(2026, 11, 2, 23, 59);

      expect(AppDateFormatter.formatTime(dtMidnight), '00:05');
      expect(AppDateFormatter.formatTime(dtMorning), '09:30');
      expect(AppDateFormatter.formatTime(dtAfternoon), '14:05');
      expect(AppDateFormatter.formatTime(dtNight), '23:59');

      expect(AppDateFormatter.formatDateTime(dtMidnight), '02 Nov 2026, 00:05');
      expect(AppDateFormatter.formatDateTime(dtNight), '02 Nov 2026, 23:59');
    });

    test('Handles raw SQL string without Z as UTC', () {
      const rawSqlString = '2026-11-02 05:04:00';
      final localDt = AppDateFormatter.parseUtcToLocal(rawSqlString);

      expect(localDt.isUtc, isFalse);
      final localOffset = DateTime.now().timeZoneOffset;
      if (localOffset.inHours == 5 && localOffset.inMinutes == 330) {
        expect(AppDateFormatter.formatTime(localDt), '10:34');
        expect(AppDateFormatter.formatDateTime(localDt), '02 Nov 2026, 10:34');
      }
    });

    test('DetectionResult.fromJson parses UTC created_at into local timezone', () {
      final json = {
        'id': 'scan-123',
        'crop_type': 'Chilli',
        'detection_status': 'detected',
        'total_detections': 1,
        'highest_confidence': 0.92,
        'processing_time_sec': 0.15,
        'model_version': 'yolo11s-v1.0',
        'created_at': '2026-11-02T05:04:00Z',
        'detections': [
          {
            'pest_name': 'Thrips',
            'confidence': 0.92,
            'x_min': 0.1,
            'y_min': 0.1,
            'x_max': 0.5,
            'y_max': 0.5
          }
        ]
      };

      final result = DetectionResult.fromJson(json);
      expect(result.createdAt.isUtc, isFalse);

      final localOffset = DateTime.now().timeZoneOffset;
      if (localOffset.inHours == 5 && localOffset.inMinutes == 330) {
        expect(AppDateFormatter.formatTime(result.createdAt), '10:34');
        expect(AppDateFormatter.formatDateTime(result.createdAt), '02 Nov 2026, 10:34');
      }
    });
  });
}
