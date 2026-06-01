import 'package:flutter_test/flutter_test.dart';
import 'package:cogctl_ux/main.dart';

void main() {
  testWidgets('Dashboard launches and displays title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CogctlUxApp());

    // Verify that our dashboard shows the title
    expect(find.text('RFC 9179 Geo-Location Specs'), findsOneWidget);
  });
}
