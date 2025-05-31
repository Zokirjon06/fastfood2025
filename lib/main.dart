import 'package:fastfood/di/di.dart';
import 'package:fastfood/firebase_options.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/presentation/pages/auth/login_page.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/screens/order_lis_page.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Main entry point of the FastFood application
/// Initializes all required services and dependencies
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set preferred orientations for better UX
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize core services
    await _initializeServices();

    // Run the application
    runApp(const FastFoodApp());
  } catch (error, stackTrace) {
    // Log initialization errors
    debugPrint('❌ App initialization failed: $error');
    debugPrint('Stack trace: $stackTrace');

    // Run minimal error app
    runApp(const ErrorApp());
  }
}

/// Initializes all required services in the correct order
Future<void> _initializeServices() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized successfully');

  // Initialize Hive storage
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  await Hive.openBox("workType");
  debugPrint('✅ Hive storage initialized successfully');

  // Initialize dependency injection
  await initializeDependencies();
  debugPrint('✅ Dependencies initialized successfully');
}

/// Error app widget for initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Ilovani ishga tushirishda xatolik',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Iltimos, ilovani qayta ishga tushiring',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main FastFood application widget
class FastFoodApp extends StatefulWidget {
  const FastFoodApp({super.key});

  @override
  State<FastFoodApp> createState() => _FastFoodAppState();
}

class _FastFoodAppState extends State<FastFoodApp> {
  // Cached instances for better performance
  late final Box _authBox;
  static const String _initialQuery = '';

  @override
  void initState() {
    super.initState();
    _authBox = Hive.box("workType");
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _buildBlocProviders(),
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FastFood Admin',
          theme: _buildAppTheme(),
          home: _buildHomeWidget(),
        ),
      ),
    );
  }

  /// Creates optimized BLoC providers
  List<BlocProvider> _buildBlocProviders() {
    return [
      BlocProvider<ProductCubit>(
        create: (_) => sl<ProductCubit>()..getProducts(_initialQuery),
      ),
      BlocProvider<AuthCubit>(
        create: (_) => sl<AuthCubit>(),
      ),
    ];
  }

  /// Builds the app theme with consistent styling
  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.amber,
      primaryColor: Colors.amber.shade700,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds the home widget based on authentication state
  Widget _buildHomeWidget() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return _getPageForAuthState(authState);
      },
    );
  }

  /// Returns the appropriate page based on authentication state
  Widget _getPageForAuthState(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.authenticated:
        return _getAuthenticatedPage();

      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LoginPage();

      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashPage();
    }
  }

  /// Returns the appropriate page for authenticated users
  Widget _getAuthenticatedPage() {
    if (_authBox.values.isEmpty) {
      return const SplashPage();
    }

    final userRole = _authBox.values.first as String;
    switch (userRole) {
      case 'admin':
        return const HomePage();
      case 'chef':
        return const OrderListPage();
      default:
        return const SplashPage();
    }
  }
}
