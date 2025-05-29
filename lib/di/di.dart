// di.dart - Dependency Injection Entry Point
// This file provides a clean interface for dependency injection throughout the app

export 'injection_container.dart';

// Re-export GetIt for convenience
import 'package:get_it/get_it.dart';
import 'injection_container.dart';

/// Global service locator instance
/// Use this to access dependencies throughout the app
final GetIt sl = InjectionContainer.instance;

/// Initialize all dependencies
/// This function should be called once at app startup
Future<void> initializeDependencies() async {
  await InjectionContainer.init();
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await InjectionContainer.reset();
}

/// Check if dependencies are initialized
bool get isDependenciesInitialized => InjectionContainer.isInitialized;
