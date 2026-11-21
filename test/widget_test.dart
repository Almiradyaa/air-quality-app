import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality_app/main.dart';

void main() {
  testWidgets('Air Quality App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AirQualityApp());
  });
}