import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';
import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:fastfood/layers/presentation/pages/screens/order_lis_page.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

// Generate mocks
@GenerateMocks([LoginUseCase, AuthRepository])
import 'main_app_routing_test.mocks.dart';

void main() {
  group('Main App Routing Security Tests', () {
    late MockLoginUseCase mockLoginUseCase;
    late MockAuthRepository mockAuthRepository;
    late Box mockBox;

    setUpAll(() async {
      await setUpTestHive();
    });

    setUp(() async {
      mockLoginUseCase = MockLoginUseCase();
      mockAuthRepository = MockAuthRepository();
      
      // Setup Hive box
      mockBox = await Hive.openBox('workType');
      
      // Setup default auth state stream
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
    });

    tearDown(() async {
      await mockBox.clear();
      await mockBox.close();
    });

    tearDownAll(() async {
      await tearDownTestHive();
    });

    Widget createTestApp(AuthCubit authCubit) {
      return MaterialApp(
        home: BlocBuilder<AuthCubit, AuthState>(
          bloc: authCubit,
          builder: (context, authState) {
            // Handle authentication states securely
            switch (authState.status) {
              case AuthStatus.authenticated:
                // Only authenticated users can access protected pages
                return mockBox.values.isEmpty
                    ? const SplashPage()
                    : mockBox.values.first == 'admin'
                        ? const HomePage()
                        : const OrderListPage();
              
              case AuthStatus.unauthenticated:
              case AuthStatus.error:
                // Unauthenticated or error states go to login
                return const LoginPage();
              
              case AuthStatus.initial:
              case AuthStatus.loading:
                // Show splash for initial/loading states
                return const SplashPage();
            }
          },
        ),
      );
    }

    group('Unauthenticated User Routing', () {
      testWidgets('should show login page for unauthenticated users', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        // Simulate unauthenticated state
        authCubit.emit(const AuthState(status: AuthStatus.unauthenticated));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show login page
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(OrderListPage), findsNothing);

        await authCubit.close();
      });

      testWidgets('should show login page for error states', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        // Simulate error state
        authCubit.emit(const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Authentication failed',
        ));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show login page even on error
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(OrderListPage), findsNothing);

        await authCubit.close();
      });
    });

    group('Authenticated User Routing', () {
      testWidgets('should show admin home page for authenticated admin users', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        final user = UserEntity(
          uid: 'admin-uid',
          email: 'admin@test.com',
          displayName: 'Admin User',
        );

        // Set admin role in Hive
        await mockBox.put('role', 'admin');

        // Simulate authenticated state
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show home page for admin
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(OrderListPage), findsNothing);

        await authCubit.close();
      });

      testWidgets('should show order list page for authenticated regular users', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        final user = UserEntity(
          uid: 'user-uid',
          email: 'user@test.com',
          displayName: 'Regular User',
        );

        // Set regular user role in Hive
        await mockBox.put('role', 'user');

        // Simulate authenticated state
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show order list page for regular user
        expect(find.byType(OrderListPage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(HomePage), findsNothing);

        await authCubit.close();
      });

      testWidgets('should show splash page for authenticated users without role', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        final user = UserEntity(
          uid: 'user-uid',
          email: 'user@test.com',
          displayName: 'User Without Role',
        );

        // Don't set any role in Hive (empty box)
        await mockBox.clear();

        // Simulate authenticated state
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show splash page when no role is set
        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(OrderListPage), findsNothing);

        await authCubit.close();
      });
    });

    group('Initial and Loading States', () {
      testWidgets('should show splash page for initial state', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        // Keep initial state
        expect(authCubit.state.status, AuthStatus.initial);

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show splash page for initial state
        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(HomePage), findsNothing);

        await authCubit.close();
      });

      testWidgets('should show splash page for loading state', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        // Simulate loading state
        authCubit.emit(const AuthState(
          status: AuthStatus.loading,
          isLoading: true,
        ));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show splash page for loading state
        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(HomePage), findsNothing);

        await authCubit.close();
      });
    });

    group('Security Validation', () {
      testWidgets('should NEVER show protected pages without authentication', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        // Set admin role in Hive but keep user unauthenticated
        await mockBox.put('role', 'admin');

        // Simulate unauthenticated state
        authCubit.emit(const AuthState(status: AuthStatus.unauthenticated));

        await tester.pumpWidget(createTestApp(authCubit));
        await tester.pumpAndSettle();

        // Should show login page despite having admin role in storage
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(HomePage), findsNothing);
        expect(find.byType(OrderListPage), findsNothing);

        await authCubit.close();
      });

      testWidgets('should handle state transitions securely', 
          (WidgetTester tester) async {
        final authCubit = AuthCubit(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );

        await tester.pumpWidget(createTestApp(authCubit));

        // Start with initial state (splash)
        expect(find.byType(SplashPage), findsOneWidget);

        // Transition to unauthenticated (login)
        authCubit.emit(const AuthState(status: AuthStatus.unauthenticated));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);

        // Transition to authenticated (protected page)
        await mockBox.put('role', 'admin');
        authCubit.emit(AuthState(
          status: AuthStatus.authenticated,
          user: UserEntity(uid: 'test', email: 'test@test.com'),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);

        // Transition back to error (login)
        authCubit.emit(const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Session expired',
        ));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);

        await authCubit.close();
      });
    });
  });
}
