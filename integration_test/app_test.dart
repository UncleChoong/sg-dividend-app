import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg_dividend/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('input → optimize → result has at least one allocation line', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SgDividendApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Should be on input screen
    expect(find.text('Optimize'), findsOneWidget);

    await tester.tap(find.text('Optimize'));
    await tester.pumpAndSettle();

    // Result screen shows projected dividend (S$ currency symbol appears)
    expect(find.textContaining('S\$'), findsWidgets);
  });
}
