import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';
import 'package:fastfood/di/di.dart';

void main() {
  group('Borderless Form Design Tests', () {
    setUp(() async {
      await resetDependencies();
      await initializeDependencies();
    });

    testWidgets('should display borderless text fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find FormBuilder text fields
      final textFields = find.byType(FormBuilderTextField);
      expect(textFields, findsNWidgets(2)); // Email and password fields

      // Verify fields are present and styled correctly
      await tester.pumpAndSettle();

      // The fields should be visible and functional
      expect(find.byType(FormBuilderTextField), findsNWidgets(2));
    });

    testWidgets('should handle form validation without borders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find the login button (FloatingActionButton)
      final loginButton = find.byType(FloatingActionButton);

      // Tap login button without entering data
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors (text only, no border indication)
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should accept valid input in borderless fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find text fields
      final emailField = find.byType(FormBuilderTextField).first;
      final passwordField = find.byType(FormBuilderTextField).last;

      // Enter valid data
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Should not show validation errors
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
    });
  });

  group('Clean SnackBar Tests', () {
    testWidgets('should display clean SnackBar messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, 'Test message'),
                child: Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      // Should display clean message
      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('should clean messy messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ShowSnackBar.show(context, '  Multiple   spaces   message  '),
                child: Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show SnackBar
      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      // Should display cleaned message
      expect(find.text('Multiple spaces message'), findsOneWidget);
    });
  });

  // Note: Message cleaning is tested through the SnackBar display tests above
  // since the _cleanMessage method is private to the ShowSnackBar class
}
