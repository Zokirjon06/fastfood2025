import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';

void main() {
  group('ShowSnackBar Tests', () {
    testWidgets('should display simple SnackBar with clean message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, 'Test message'),
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      // Should display the message
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('should handle error messages from authentication', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, 'Invalid email or password'),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show error SnackBar
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Should display the error message
      expect(find.text('Invalid email or password'), findsOneWidget);
    });

    testWidgets('should trim whitespace from messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, '  Trimmed message  '),
                child: const Text('Show Trimmed'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show Trimmed'));
      await tester.pumpAndSettle();

      // Should display the trimmed message
      expect(find.text('Trimmed message'), findsOneWidget);
    });

    testWidgets('should handle empty messages gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, ''),
                child: const Text('Show Empty'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show Empty'));
      await tester.pumpAndSettle();

      // Should still show SnackBar (even if empty)
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should display SnackBar for 2 seconds', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, 'Timed message'),
                child: const Text('Show Timed'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show Timed'));
      await tester.pump();

      // Should be visible immediately
      expect(find.text('Timed message'), findsOneWidget);

      // Wait for 1 second - should still be visible
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Timed message'), findsOneWidget);

      // Wait for another 2 seconds - should be gone
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Timed message'), findsNothing);
    });
  });
}
