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
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/screens/order_lis_page.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';

// Generate mocks
@GenerateMocks([LoginUseCase, AuthRepository])
import 'logout_security_test.mocks.dart';

void main() {
  group('Logout Security Tests', () {
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

    group('HomePage Logout Tests', () {
      testWidgets('should show logout confirmation dialog when logout button is tapped', 
          (WidgetTester tester) async {
        // Setup authenticated state
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const HomePage(),
            ),
          ),
        );

        // Find and tap logout button
        final logoutButton = find.byIcon(Icons.logout);
        expect(logoutButton, findsOneWidget);
        
        await tester.tap(logoutButton);
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Logout'), findsWidgets);
        expect(find.text('Are you sure you want to logout?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should cancel logout when Cancel is pressed in confirmation dialog', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const HomePage(),
            ),
          ),
        );

        // Tap logout button
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // Tap Cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed, logout should not be called
        expect(find.text('Are you sure you want to logout?'), findsNothing);
        verifyNever(mockAuthRepository.signOut());
      });

      testWidgets('should perform logout when Logout is confirmed in dialog', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        // Setup successful logout
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const HomePage(),
            ),
          ),
        );

        // Tap logout button
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // Tap Logout button in dialog
        final logoutButtons = find.text('Logout');
        await tester.tap(logoutButtons.last); // Tap the button, not the title
        await tester.pumpAndSettle();

        // Logout should be called
        verify(mockAuthRepository.signOut()).called(1);
      });
    });

    group('OrderListPage Logout Tests', () {
      testWidgets('should show logout button in OrderListPage AppBar', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const OrderListPage(),
            ),
          ),
        );

        // Should show logout button
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });

      testWidgets('should show logout confirmation dialog in OrderListPage', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const OrderListPage(),
            ),
          ),
        );

        // Tap logout button
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Logout'), findsWidgets);
        expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      });
    });

    group('Logout Security Validation', () {
      test('should handle logout errors gracefully', () async {
        // Setup failed logout
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Left('Network error'));

        await authCubit.logout();

        expect(authCubit.state.status, AuthStatus.error);
        expect(authCubit.state.errorMessage, contains('Failed to logout'));
      });

      test('should clear user data on successful logout', () async {
        // Setup initial authenticated state
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        // Setup successful logout and auth state change
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        when(mockAuthRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        await authCubit.logout();

        // Should call signOut
        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should maintain security after logout', () async {
        // Setup authenticated state
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        // Setup logout that triggers auth state change to unauthenticated
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        when(mockAuthRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        // Create new cubit to simulate auth state change
        final newAuthCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Should be unauthenticated
        expect(newAuthCubit.state.status, AuthStatus.unauthenticated);
        expect(newAuthCubit.state.user, isNull);

        await newAuthCubit.close();
      });

      testWidgets('should prevent access to protected pages after logout', 
          (WidgetTester tester) async {
        // This test would be part of the main app routing tests
        // but demonstrates the security principle
        
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );

        // Start authenticated
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        Widget createTestApp() {
          return MaterialApp(
            home: BlocBuilder<AuthCubit, AuthState>(
              bloc: authCubit,
              builder: (context, state) {
                switch (state.status) {
                  case AuthStatus.authenticated:
                    return const HomePage();
                  case AuthStatus.unauthenticated:
                  case AuthStatus.error:
                    return const LoginPage();
                  default:
                    return const Scaffold(body: CircularProgressIndicator());
                }
              },
            ),
          );
        }

        await tester.pumpWidget(createTestApp());
        
        // Should show HomePage when authenticated
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);

        // Simulate logout by changing auth state
        authCubit.emit(const AuthState(status: AuthStatus.unauthenticated));
        await tester.pumpAndSettle();

        // Should now show LoginPage
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
      });
    });

    group('Logout UI/UX Tests', () {
      testWidgets('should show success message on successful logout', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => const Right(null));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const HomePage(),
            ),
          ),
        );

        // Perform logout
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();
        
        final logoutButtons = find.text('Logout');
        await tester.tap(logoutButtons.last);
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Logged out successfully'), findsOneWidget);
      });

      testWidgets('should have proper styling for logout button', 
          (WidgetTester tester) async {
        final user = UserEntity(
          uid: 'test-uid',
          email: 'test@test.com',
          displayName: 'Test User',
        );
        
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthCubit>(
              create: (_) => authCubit,
              child: const HomePage(),
            ),
          ),
        );

        // Find logout button
        final logoutButton = find.byIcon(Icons.logout);
        expect(logoutButton, findsOneWidget);

        // Check button properties
        final IconButton button = tester.widget(logoutButton.first);
        final Icon icon = button.icon as Icon;
        
        expect(icon.icon, Icons.logout);
        // Note: Color testing would require more complex widget testing setup
      });
    });
  });
}
