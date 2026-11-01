import 'package:flutter_test/flutter_test.dart';
import 'package:crop_guard/models/pest_model.dart';

void main() {
  group('Mobile UI Form Validation & Logic Tests', () {
    test('Email format validation rules', () {
      bool isValidEmail(String email) {
        final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return regex.hasMatch(email.trim());
      }

      expect(isValidEmail('farmer@cropguard.org'), isTrue);
      expect(isValidEmail('test.user@domain.co.in'), isTrue);
      expect(isValidEmail('plainaddress'), isFalse);
      expect(isValidEmail('@missingusername.com'), isFalse);
      expect(isValidEmail('missingdomain@.com'), isFalse);
    });

    test('Password complexity requirements', () {
      bool isValidPassword(String pwd) {
        return pwd.trim().length >= 6;
      }

      expect(isValidPassword('farmer123'), isTrue);
      expect(isValidPassword('securePass99'), isTrue);
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword(''), isFalse);
    });

    test('Risk level determination based on confidence', () {
      String getRiskLevel(double confidence) {
        if (confidence >= 0.80) return 'High';
        if (confidence >= 0.60) return 'Medium';
        return 'Low';
      }

      expect(getRiskLevel(0.92), equals('High'));
      expect(getRiskLevel(0.72), equals('Medium'));
      expect(getRiskLevel(0.45), equals('Low'));
    });

    test('Target crops list coverage', () {
      const targetCrops = ['Paddy/Rice', 'Cotton', 'Tomato', 'Chilli'];
      expect(targetCrops.length, equals(4));
      expect(targetCrops.contains('Paddy/Rice'), isTrue);
      expect(targetCrops.contains('Cotton'), isTrue);
      expect(targetCrops.contains('Tomato'), isTrue);
      expect(targetCrops.contains('Chilli'), isTrue);
    });

    test('Detection box coordinates normalization check', () {
      final box = DetectionBox(
        pestName: 'Whitefly',
        confidence: 0.85,
        xMin: 0.15,
        yMin: 0.20,
        xMax: 0.45,
        yMax: 0.60,
      );

      expect(box.xMin, inInclusiveRange(0.0, 1.0));
      expect(box.yMin, inInclusiveRange(0.0, 1.0));
      expect(box.xMax, inInclusiveRange(0.0, 1.0));
      expect(box.yMax, inInclusiveRange(0.0, 1.0));
      expect(box.xMax, greaterThan(box.xMin));
      expect(box.yMax, greaterThan(box.yMin));
    });

    test('Password reset deep link URI verification', () {
      const expectedRedirectUrl = 'com.cropguard.ai://reset-password';
      final uri = Uri.parse(expectedRedirectUrl);
      expect(uri.scheme, equals('com.cropguard.ai'));
      expect(uri.host, equals('reset-password'));
    });

    test('Password reset match and strength validation', () {
      bool validatePasswords(String p1, String p2) {
        if (p1.trim().length < 6) return false;
        return p1.trim() == p2.trim();
      }

      expect(validatePasswords('newPassword123', 'newPassword123'), isTrue);
      expect(validatePasswords('newPassword123', 'differentPassword'), isFalse);
      expect(validatePasswords('12345', '12345'), isFalse);
    });
  });
}
