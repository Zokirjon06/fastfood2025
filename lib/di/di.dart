// di.dart
import 'package:fastfood/layers/application/cubit/get_product_cubit.dart';
import 'package:fastfood/layers/application/cubit/auth_cubit.dart';
import 'package:fastfood/layers/data/repository/product_repository_impl.dart';
import 'package:fastfood/layers/data/repository/auth_repository_impl.dart';
import 'package:fastfood/layers/data/service/produc_service.dart';
import 'package:fastfood/layers/data/service/auth_service.dart';
import 'package:fastfood/layers/domain/usecase/get_product_usecase.dart';
import 'package:fastfood/layers/domain/usecase/login_usecase.dart';

// Product dependencies
ProductService productService = ProductService();
ProductRepositoryImpl productRepository = ProductRepositoryImpl(productService);
GetProductsUseCase getProductsUseCase = GetProductsUseCase(productRepository);
ProductCubit productCubit = ProductCubit(getProductListUseCase: getProductsUseCase);

// Authentication dependencies
AuthService authService = AuthService();
AuthRepositoryImpl authRepository = AuthRepositoryImpl(authService);
LoginUseCase loginUseCase = LoginUseCase(authRepository);
AuthCubit authCubit = AuthCubit(
  loginUseCase: loginUseCase,
  authRepository: authRepository,
);
