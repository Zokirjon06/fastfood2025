// injection_container.dart - Dependency Injection Configuration
import 'package:get_it/get_it.dart';

// Application Layer
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';

// Domain Layer - Abstractions
import 'package:fastfood/layers/domain/repository/product_repository.dart';
import 'package:fastfood/layers/domain/repository/auth_repository.dart';
import 'package:fastfood/layers/domain/usecase/get_product_usecase.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';

// Data Layer - Implementations
import 'package:fastfood/layers/data/repository/product_repository_impl.dart';
import 'package:fastfood/layers/data/repository/auth_repository_impl.dart';
import 'package:fastfood/layers/data/service/produc_service.dart';
import 'package:fastfood/layers/data/service/auth_service.dart';

/// Dependency injection configuration class
/// This class encapsulates all DI setup logic
class InjectionContainer {
  static final GetIt _sl = GetIt.instance;
  
  /// Get the service locator instance
  static GetIt get instance => _sl;
  
  /// Initialize all dependencies in the correct order
  static Future<void> init() async {
    await _initDataSources();
    await _initRepositories();
    await _initUseCases();
    await _initCubits();
  }
  
  /// Register data sources (external dependencies)
  static Future<void> _initDataSources() async {
    // Product data source
    _sl.registerLazySingleton<ProductService>(
      () => ProductService(),
    );

    // Authentication data source
    _sl.registerLazySingleton<AuthService>(
      () => AuthService(),
    );
  }

  /// Register repositories (data layer implementations)
  static Future<void> _initRepositories() async {
    // Product repository
    _sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(_sl<ProductService>()),
    );

    // Authentication repository
    _sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(_sl<AuthService>()),
    );
  }

  /// Register use cases (business logic)
  static Future<void> _initUseCases() async {
    // Product use cases
    _sl.registerLazySingleton<GetProductsUseCase>(
      () => GetProductsUseCase(_sl<ProductRepository>()),
    );

    // Authentication use cases
    _sl.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(_sl<AuthRepository>()),
    );
  }

  /// Register cubits/blocs (presentation layer state managers)
  static Future<void> _initCubits() async {
    // Product cubit - Factory registration for fresh instances
    _sl.registerFactory<ProductCubit>(
      () => ProductCubit(getProductListUseCase: _sl<GetProductsUseCase>()),
    );

    // Authentication cubit - Factory registration for fresh instances
    _sl.registerFactory<AuthCubit>(
      () => AuthCubit(
        loginUseCase: _sl<LoginUseCase>(),
        authRepository: _sl<AuthRepository>(),
      ),
    );
  }
  
  /// Reset all dependencies (useful for testing)
  static Future<void> reset() async {
    await _sl.reset();
  }
  
  /// Check if a specific type is registered
  static bool isRegistered<T extends Object>() {
    return _sl.isRegistered<T>();
  }
  
  /// Get a dependency by type
  static T get<T extends Object>() {
    return _sl<T>();
  }
  
  /// Check if all core dependencies are initialized
  static bool get isInitialized {
    return _sl.isRegistered<ProductCubit>() && 
           _sl.isRegistered<AuthCubit>() &&
           _sl.isRegistered<ProductRepository>() &&
           _sl.isRegistered<AuthRepository>();
  }
}
