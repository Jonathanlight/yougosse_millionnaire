import 'package:flutter_test/flutter_test.dart';
import 'package:millionaire_city/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MillionaireCityApp());

    // Verify that the loading screen appears
    expect(find.text('Loading City...'), findsOneWidget);
  });
}
