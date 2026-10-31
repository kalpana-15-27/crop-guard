import 'package:flutter_test/flutter_test.dart';
import 'package:crop_guard/localization/app_strings.dart';

void main() {
  group('Bilingual Localization Tests', () {
    test('Default language is English', () {
      final strings = AppStrings();
      expect(strings.currentLanguage, equals('en'));
      expect(strings.isTelugu, isFalse);
      expect(strings.tr('appName'), contains('CropGuard AI'));
    });

    test('Switch to Telugu language', () {
      final strings = AppStrings();
      strings.setLanguage('te');
      expect(strings.currentLanguage, equals('te'));
      expect(strings.isTelugu, isTrue);
      expect(strings.tr('quickScan'), contains('పురుగును'));
      expect(strings.tr('appName'), contains('క్రాప్‌గార్డ్'));

      // Switch back to English
      strings.setLanguage('en');
      expect(strings.isTelugu, isFalse);
    });

    test('Fallback to English key if translation missing', () {
      final strings = AppStrings();
      strings.setLanguage('te');
      final result = strings.tr('nonExistentKey');
      expect(result, equals('nonExistentKey'));
      strings.setLanguage('en');
    });
  });
}
