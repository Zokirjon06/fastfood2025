// bloc_providers.dart - BLoC Provider Configuration
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Application Layer
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';

// DI
import 'di.dart';

/// Provides all BLoC providers for the application
/// This centralizes BLoC provider configuration and makes it reusable
class AppBlocProviders {
  
  /// Get all BLoC providers for the main app
  static List<BlocProvider> getProviders({String initialQuery = ''}) {
    return [
      // Product Cubit Provider
      BlocProvider<ProductCubit>(
        create: (_) => sl<ProductCubit>()..getProducts(initialQuery),
      ),
      
      // Authentication Cubit Provider
      BlocProvider<AuthCubit>(
        create: (_) => sl<AuthCubit>(),
      ),
    ];
  }
  
  /// Create a MultiBlocProvider with all app providers
  static Widget createMultiBlocProvider({
    required Widget child,
    String initialQuery = '',
  }) {
    return MultiBlocProvider(
      providers: getProviders(initialQuery: initialQuery),
      child: child,
    );
  }
  
  /// Get individual provider for specific use cases
  static BlocProvider<ProductCubit> getProductProvider({String initialQuery = ''}) {
    return BlocProvider<ProductCubit>(
      create: (_) => sl<ProductCubit>()..getProducts(initialQuery),
    );
  }
  
  static BlocProvider<AuthCubit> getAuthProvider() {
    return BlocProvider<AuthCubit>(
      create: (_) => sl<AuthCubit>(),
    );
  }
}

/// Extension to make BLoC access cleaner
extension BlocContextExtension on BuildContext {
  /// Get ProductCubit from context
  ProductCubit get productCubit => read<ProductCubit>();
  
  /// Get AuthCubit from context
  AuthCubit get authCubit => read<AuthCubit>();
  
  /// Watch ProductCubit state
  ProductState get productState => watch<ProductCubit>().state;
  
  /// Watch AuthCubit state
  AuthState get authState => watch<AuthCubit>().state;
}
