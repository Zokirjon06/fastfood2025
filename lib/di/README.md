# Dependency Injection Architecture

This directory contains the dependency injection (DI) configuration for the FastFood Flutter application. The DI system follows clean architecture principles and uses the GetIt service locator pattern.

## Architecture Overview

The DI system is organized into several layers following the dependency rule (outer layers depend on inner layers):

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│                   (Cubits/BLoCs)                           │
├─────────────────────────────────────────────────────────────┤
│                   Application Layer                         │
│                    (Use Cases)                             │
├─────────────────────────────────────────────────────────────┤
│                     Domain Layer                           │
│              (Entities & Repositories)                     │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                            │
│           (Repository Implementations & Services)          │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/di/
├── di.dart                    # Main DI entry point
├── injection_container.dart   # Core DI configuration
├── bloc_providers.dart       # BLoC provider helpers
└── README.md                 # This documentation
```

## Core Components

### 1. InjectionContainer (`injection_container.dart`)

The main DI configuration class that handles all dependency registration:

- **Data Sources**: External services (Firebase, APIs)
- **Repositories**: Data layer implementations
- **Use Cases**: Business logic components
- **Cubits**: Presentation layer state managers

### 2. Service Locator (`di.dart`)

Provides a clean interface for accessing dependencies throughout the app:

```dart
// Get a dependency
final authCubit = sl<AuthCubit>();

// Check if initialized
if (isDependenciesInitialized) {
  // App is ready
}
```

### 3. BLoC Providers (`bloc_providers.dart`)

Centralizes BLoC provider configuration for the widget tree:

```dart
// Use in main app
AppBlocProviders.createMultiBlocProvider(
  initialQuery: 'search',
  child: MyApp(),
)

// Access via context extensions
context.authCubit.login(email: email, password: password);
```

## Registration Types

### Singleton Registration
Used for services and repositories that should have a single instance:

```dart
sl.registerLazySingleton<AuthService>(() => AuthService());
```

### Factory Registration
Used for cubits that need fresh instances:

```dart
sl.registerFactory<AuthCubit>(() => AuthCubit(...));
```

## Usage Examples

### 1. Initializing Dependencies

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp();
  
  // Initialize DI
  await initializeDependencies();
  
  runApp(MyApp());
}
```

### 2. Using Dependencies in Widgets

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Access cubit via context extension
        final authCubit = context.authCubit;
        
        return ElevatedButton(
          onPressed: () => authCubit.login(email: email, password: password),
          child: Text('Login'),
        );
      },
    );
  }
}
```

### 3. Testing with DI

```dart
void main() {
  setUp(() async {
    await resetDependencies();
    await initializeDependencies();
  });
  
  test('should login successfully', () async {
    final authCubit = sl<AuthCubit>();
    // Test logic here
  });
}
```

## Benefits

### 1. **Testability**
- Easy to mock dependencies for unit tests
- Clean separation of concerns
- Isolated testing of individual components

### 2. **Maintainability**
- Centralized dependency configuration
- Clear dependency hierarchy
- Easy to add new dependencies

### 3. **Scalability**
- Supports complex dependency graphs
- Lazy loading of dependencies
- Memory efficient with proper lifecycle management

### 4. **Clean Architecture Compliance**
- Respects dependency rule
- Abstractions over implementations
- Proper layer separation

## Best Practices

### 1. **Registration Order**
Always register dependencies in the correct order:
1. Data Sources (external services)
2. Repositories (data layer)
3. Use Cases (business logic)
4. Cubits (presentation layer)

### 2. **Interface Usage**
Register interfaces, not concrete implementations:

```dart
// Good
sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(...));

// Avoid
sl.registerLazySingleton<AuthRepositoryImpl>(() => AuthRepositoryImpl(...));
```

### 3. **Lifecycle Management**
- Use `registerLazySingleton` for services and repositories
- Use `registerFactory` for cubits and short-lived objects
- Always reset dependencies in tests

### 4. **Error Handling**
The DI system includes proper error handling and validation:

```dart
// Check if dependencies are registered
if (sl.isRegistered<AuthCubit>()) {
  // Safe to use
}

// Graceful initialization checking
if (isDependenciesInitialized) {
  // All core dependencies are ready
}
```

## Migration from Global Variables

The previous global variable approach has been completely replaced with this professional DI system:

**Before:**
```dart
// Global variables (deprecated)
AuthCubit authCubit = AuthCubit(...);
ProductCubit productCubit = ProductCubit(...);
```

**After:**
```dart
// Service locator pattern
final authCubit = sl<AuthCubit>();
final productCubit = sl<ProductCubit>();
```

This provides better testability, maintainability, and follows industry best practices for Flutter applications.
