import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';

// Generate mocks
@GenerateMocks([LoginUseCase, AuthRepository])
import 'auth_security_test.mocks.dart';

void main() {
  group('Authentication Security Tests', () {
    late MockLoginUseCase mockLoginUseCase;
    late MockAuthRepository mockAuthRepository;
    late AuthCubit authCubit;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
      mockAuthRepository = MockAuthRepository();
      
      // Setup default auth state stream
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      
      authCubit = AuthCubit(
        loginUseCase: mockLoginUseCase,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() {
      authCubit.close();
    });

    group('Login Security Tests', () {
      testWidgets('should NOT navigate to home page with invalid credentials', 
          (WidgetTester tester) async {
        // Setup failed login
        when(mockLoginUseCase(email: 'invalid@test.com', password: 'wrong'))
            .thenAnswer((_) async => const Left('Invalid credentials'));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const LoginPage(),
            ),
          ),
        );

        // Enter invalid credentials
        await tester.enterText(
          find.byType(TextFormField).first, 
          'invalid@test.com'
        );
        await tester.enterText(
          find.byType(TextFormField).last, 
          'wrong'
        );

        // Tap login button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Should still be on login page
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        
        // Should show error message
        expect(find.text('Invalid credentials'), findsOneWidget);
      });

      testWidgets('should navigate to home page ONLY with valid credentials', 
          (WidgetTester tester) async {
        final validUser = UserEntity(
          uid: 'test-uid',
          email: 'valid@test.com',
          displayName: 'Test User',
        );

        // Setup successful login
        when(mockLoginUseCase(email: 'valid@test.com', password: 'correct'))
            .thenAnswer((_) async => Right(validUser));

        // Setup auth state change to authenticated
        when(mockAuthRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(validUser));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const LoginPage(),
            ),
          ),
        );

        // Enter valid credentials
        await tester.enterText(
          find.byType(TextFormField).first, 
          'valid@test.com'
        );
        await tester.enterText(
          find.byType(TextFormField).last, 
          'correct'
        );

        // Tap login button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Verify login was called with correct credentials
        verify(mockLoginUseCase(email: 'valid@test.com', password: 'correct'))
            .called(1);
      });

      testWidgets('should disable login button during authentication', 
          (WidgetTester tester) async {
        // Setup delayed login response
        when(mockLoginUseCase(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return const Left('Network error');
        });

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const LoginPage(),
            ),
          ),
        );

        // Enter credentials
        await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
        await tester.enterText(find.byType(TextFormField).last, 'password');

        // Tap login button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump(); // Don't wait for completion

        // Button should be disabled (onPressed is null)
        final FloatingActionButton button = tester.widget(find.byType(FloatingActionButton));
        expect(button.onPressed, isNull);
        
        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      test('should clear errors before new login attempt', () async {
        // Setup initial error state
        when(mockLoginUseCase(email: 'test@test.com', password: 'wrong'))
            .thenAnswer((_) async => const Left('Invalid password'));

        // First failed login
        await authCubit.login(email: 'test@test.com', password: 'wrong');
        expect(authCubit.state.status, AuthStatus.error);
        expect(authCubit.state.errorMessage, 'Invalid password');

        // Clear error
        authCubit.clearError();
        expect(authCubit.state.errorMessage, isNull);
        expect(authCubit.state.status, AuthStatus.error); // Status remains error until new action
      });
    });

    group('Authentication State Security', () {
      test('should start with unauthenticated state', () {
        expect(authCubit.state.status, AuthStatus.initial);
        expect(authCubit.state.user, isNull);
        expect(authCubit.state.isLoading, isFalse);
      });

      test('should handle authentication state changes securely', () async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );

        // Simulate auth state change to authenticated
        when(mockAuthRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(user));

        // Create new cubit to trigger auth state subscription
        final newAuthCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(newAuthCubit.state.status, AuthStatus.authenticated);
        expect(newAuthCubit.state.user, user);

        await newAuthCubit.close();
      });

      test('should handle logout securely', () async {
        // Setup successful logout
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));

        await authCubit.logout();

        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should handle logout errors', () async {
        // Setup failed logout
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Left('Logout failed'));

        await authCubit.logout();

        expect(authCubit.state.status, AuthStatus.error);
        expect(authCubit.state.errorMessage, contains('Failed to logout'));
      });
    });

    group('Error Handling Security', () {
      test('should properly handle network errors', () async {
        when(mockLoginUseCase(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => const Left('Network connection failed'));

        await authCubit.login(email: 'test@test.com', password: 'password');

        expect(authCubit.state.status, AuthStatus.error);
        expect(authCubit.state.errorMessage, 'Network connection failed');
        expect(authCubit.state.user, isNull);
        expect(authCubit.state.isLoading, isFalse);
      });

      test('should properly handle authentication errors', () async {
        when(mockLoginUseCase(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => const Left('Wrong password provided for that user.'));

        await authCubit.login(email: 'test@test.com', password: 'wrongpassword');

        expect(authCubit.state.status, AuthStatus.error);
        expect(authCubit.state.errorMessage, 'Wrong password provided for that user.');
        expect(authCubit.state.user, isNull);
        expect(authCubit.state.isLoading, isFalse);
      });
    });
  });
}
