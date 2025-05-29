// dependency_injection_test.dart - Tests for DI architecture
import 'package:flutter_test/flutter_test.dart';

// DI
import 'package:fastfood/di/di.dart';

// Domain Layer
import 'package:fastfood/layers/domain/repository/product_repository.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';
import 'package:fastfood/layers/domain/usecase/get_product_usecase.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';

// Data Layer
import 'package:fastfood/layers/data/service/produc_service.dart';
import 'package:fastfood/layers/data/service/auth_service.dart';

// Application Layer
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';

void main() {
  group('Dependency Injection Tests', () {
    setUp(() async {
      // Reset dependencies before each test
      await resetDependencies();
    });

    tearDown(() async {
      // Clean up after each test
      await resetDependencies();
    });

    test('should initialize all dependencies correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(isDependenciesInitialized, isTrue);
      expect(InjectionContainer.isInitialized, isTrue);
    });

    test('should register data sources correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(sl.isRegistered<ProductService>(), isTrue);
      expect(sl.isRegistered<AuthService>(), isTrue);

      // Verify instances can be retrieved
      final productService = sl<ProductService>();
      final authService = sl<AuthService>();

      expect(productService, isNotNull);
      expect(authService, isNotNull);
    });

    test('should register repositories correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(sl.isRegistered<ProductRepository>(), isTrue);
      expect(sl.isRegistered<AuthRepository>(), isTrue);

      // Verify instances can be retrieved
      final productRepo = sl<ProductRepository>();
      final authRepo = sl<AuthRepository>();

      expect(productRepo, isNotNull);
      expect(authRepo, isNotNull);
    });

    test('should register use cases correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(sl.isRegistered<GetProductsUseCase>(), isTrue);
      expect(sl.isRegistered<LoginUseCase>(), isTrue);

      // Verify instances can be retrieved
      final getProductsUseCase = sl<GetProductsUseCase>();
      final loginUseCase = sl<LoginUseCase>();

      expect(getProductsUseCase, isNotNull);
      expect(loginUseCase, isNotNull);
    });

    test('should register cubits correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(sl.isRegistered<ProductCubit>(), isTrue);
      expect(sl.isRegistered<AuthCubit>(), isTrue);

      // Verify instances can be retrieved
      final productCubit = sl<ProductCubit>();
      final authCubit = sl<AuthCubit>();

      expect(productCubit, isNotNull);
      expect(authCubit, isNotNull);
    });

    test('should provide fresh instances for factory registrations', () async {
      // Act
      await initializeDependencies();

      // Assert - Cubits should be factory registered (new instances each time)
      final productCubit1 = sl<ProductCubit>();
      final productCubit2 = sl<ProductCubit>();
      final authCubit1 = sl<AuthCubit>();
      final authCubit2 = sl<AuthCubit>();

      expect(productCubit1, isNot(same(productCubit2)));
      expect(authCubit1, isNot(same(authCubit2)));
    });

    test('should provide same instances for singleton registrations', () async {
      // Act
      await initializeDependencies();

      // Assert - Services and repositories should be singletons
      final productService1 = sl<ProductService>();
      final productService2 = sl<ProductService>();
      final authService1 = sl<AuthService>();
      final authService2 = sl<AuthService>();

      expect(productService1, same(productService2));
      expect(authService1, same(authService2));
    });

    test('should reset dependencies correctly', () async {
      // Arrange
      await initializeDependencies();
      expect(isDependenciesInitialized, isTrue);

      // Act
      await resetDependencies();

      // Assert
      expect(sl.isRegistered<ProductCubit>(), isFalse);
      expect(sl.isRegistered<AuthCubit>(), isFalse);
      expect(sl.isRegistered<ProductRepository>(), isFalse);
      expect(sl.isRegistered<AuthRepository>(), isFalse);
    });

    test('should handle dependency injection container methods correctly', () async {
      // Act
      await initializeDependencies();

      // Assert
      expect(InjectionContainer.isRegistered<ProductCubit>(), isTrue);
      expect(InjectionContainer.isRegistered<AuthCubit>(), isTrue);

      final productCubit = InjectionContainer.get<ProductCubit>();
      final authCubit = InjectionContainer.get<AuthCubit>();

      expect(productCubit, isNotNull);
      expect(authCubit, isNotNull);
    });
  });
}
