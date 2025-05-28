// get_products_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/domain/repository/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<Either<String, List<ProductEntity>>> call(String query) async {
    return repository.getProducts(query);
  }
}
