import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crop_guard/localization/app_strings.dart';
import 'package:crop_guard/widgets/crop_chip.dart';
import 'package:crop_guard/widgets/stat_card.dart';
import 'package:crop_guard/widgets/disclaimer_banner.dart';

void main() {
  group('CropGuard Reusable UI Widgets Tests', () {
    testWidgets('CropChip renders label and responds to selection', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CropChip(
              label: 'Paddy/Rice',
              isSelected: true,
              onSelected: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Paddy/Rice'), findsOneWidget);
      await tester.tap(find.byType(CropChip));
      expect(tapped, isTrue);
    });

    testWidgets('StatCard displays value and title accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total Scans',
              value: '18',
              icon: Icons.qr_code,
            ),
          ),
        ),
      );

      expect(find.text('Total Scans'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('DisclaimerBanner displays experimental notice', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppStrings()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DisclaimerBanner(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
