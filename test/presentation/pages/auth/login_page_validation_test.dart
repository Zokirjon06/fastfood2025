import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/di/di.dart';

void main() {
  group('LoginPage Production Validation Tests', () {
    setUp(() async {
      await resetDependencies();
      await initializeDependencies();
    });

    testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find the FormBuilder fields
      final emailField = find.byKey(const Key('email'));
      final passwordField = find.byKey(const Key('password'));
      final loginButton = find.text('Sign In');

      // Tap login button without entering any data
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find email field and enter invalid email
      final emailField = find.byType(FormBuilderTextField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password length', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find password field and enter short password
      final passwordField = find.byType(FormBuilderTextField).last;
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();

      // Should show password length validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should accept valid email and password', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Enter valid email and password
      final emailField = find.byType(FormBuilderTextField).first;
      final passwordField = find.byType(FormBuilderTextField).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Should not show validation errors
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Please enter a valid email address'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (context) => sl<AuthCubit>(),
            child: const LoginPage(),
          ),
        ),
      );

      // Find password field and visibility toggle
      final passwordField = find.byType(FormBuilderTextField).last;
      final visibilityToggle = find.byIcon(Icons.visibility_off);

      // Enter password
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Should show visibility icon (password visible)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
