import 'package:fastfood/di/di.dart';
import 'package:fastfood/firebase_options.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized successfully');
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  await Hive.openBox("workType");
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
          create: (_) => productCubit..getProducts(query),
        ),
        BlocProvider(
          create: (_) => authCubit,
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
              // If user is authenticated, show the appropriate page based on role
              if (authState.status == AuthStatus.authenticated) {
                return auth.values.isEmpty
                    ? SplashPage()
                    : auth.values.first == 'admin'
                        ? HomePage()
                        : OrderListPage();
              }

              // If user is not authenticated, show login page
              if (authState.status == AuthStatus.unauthenticated) {
                return LoginPage();
              }

              // For initial/loading states, show splash or loading
              return auth.values.isEmpty
                  ? SplashPage()
                  : auth.values.first == 'admin'
                      ? HomePage()
                      : OrderListPage();
            },
          ),
        ),
      ),
    );
  }
}
