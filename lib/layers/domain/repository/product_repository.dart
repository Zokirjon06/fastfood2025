// product_repository.dart
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ProductRepository {
  Future<Either<String, List<ProductEntity>>> getProducts(String query);
  // Future<void> addProduct(ProductEntity product);
}
