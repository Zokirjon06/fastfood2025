import 'package:fastfood/layers/domain/entity/user_entity.dart';
import 'package:fastfood/layers/presentation/pages/home_page.dart';
import 'package:fastfood/layers/presentation/pages/splash_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/presentation/widgets/custom_text_field.dart';
import 'package:fastfood/layers/presentation/widgets/show_snack_bar_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        context.read<AuthCubit>().login(
            UserEntity(_emailController.text.trim(), _passwordController.text));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Simple error handling for restaurant project
        if (state.status == AuthStatus.error) {
          return ShowSnackBar.show(context, state.errorMessage!);
        }
        if (state.status == AuthStatus.success) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SplashPage()),
              (route) => false);
        }
        // Note: Navigation is handled by main app routing, not here
      },
      child: Scaffold(
        floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () {
                if (state.status == AuthStatus.error) {
                  debugPrint('xato${AuthStatus.error}');
                }
                
                _login();
              }, // Disable when loading
              shape: const CircleBorder(),
              backgroundColor: state.status == AuthStatus.loading
                  ? Colors.grey
                  : Colors.amber,
              child: state.status == AuthStatus.loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Icon(
                      Icons.login,
                      size: 30.sp,
                      color: Colors.white,
                    ),
            );
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(60.h),

                  // Logo/Header Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.h,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fastfood,
                            size: 50.sp,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        Gap(24.h),
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Gap(8.h),
                        Text(
                          'Sign in to continue to FastFood',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap(48.h),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    labelText: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  Gap(20.h),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    labelText: 'Password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  Gap(40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
