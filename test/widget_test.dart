import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitchcraft/core/widgets/neo_card.dart';

void main() {
  testWidgets('NeoCard displays child widget and reacts to taps', (WidgetTester tester) async {
    bool tapped = false;

    // Build the widget in isolation (NeoCard doesn't use GoogleFonts directly)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NeoCard(
          onTap: () => tapped = true,
          child: const Text('Test Child Widget Content'),
        ),
      ),
    ));

    // Verify Child visibility
    expect(find.text('Test Child Widget Content'), findsOneWidget);

    // Verify Tap interaction
    await tester.tap(find.byType(NeoCard));
    expect(tapped, isTrue);
  });
}
