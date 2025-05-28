import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/domain/usecase/get_product_usecase.dart';

part 'get_product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit({required GetProductsUseCase getProductListUseCase})
      : _getProductListUseCase = getProductListUseCase,
        super(const ProductState());

  final GetProductsUseCase _getProductListUseCase;

  Future<void> getProducts(String query) async {
    emit(state.copyWith(status: ProductStatus.loading));

    final result = await _getProductListUseCase(query);
    

   result.fold(
    (e) => emit(state.copyWith(status: ProductStatus.failed, error: 'Ma\'lumotlar bo\'sh')),
    (d) => emit(state.copyWith(status: ProductStatus.success, products: d)));
  }
}
