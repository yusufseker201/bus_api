import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bus_density_app/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const BusDensityApp());
    await tester.pumpAndSettle();

    expect(find.text('Ana Sayfa'), findsOneWidget);
  });
}
