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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');

  // Initialize Hive
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  await Hive.openBox("workType");

  // Initialize dependency injection
  await initializeDependencies();
  print('✅ Dependencies initialized successfully');

  runApp(const MyApp());
  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => const MyApp(), // Wrap your app
  //   ),
  // );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //
  String query = '';
  var auth = Hive.box("workType");
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ProductCubit>()..getProducts(query),
        ),
        BlocProvider(
          create: (_) => sl<AuthCubit>(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                switch (authState.status) {
                  case AuthStatus.authenticated:
                    // Check for role in authentication values
                    if (auth.values.isEmpty) {
                      return const SplashPage();
                    } else if (auth.values.first == 'admin') {
                      return const HomePage();
                    } else {
                      return const OrderListPage();
                    }

                  case AuthStatus.unauthenticated:
                  case AuthStatus.error:
                    return const LoginPage();

                  case AuthStatus.initial:
                  case AuthStatus.loading:
                    return const SplashPage(); // Show splash during init/load
                }
              },
            )),
      ),
    );
  }
}
