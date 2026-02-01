import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/main.dart';

void main() {
  testWidgets('App compiles and runs smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StitchCraftApp());

    // Verify key screens are present in navigation (by checking no crash)
    // Since Splash is async, just verifying pump works is a good start for smoke test.
    await tester.pumpAndSettle();
  });
}
