// product_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/data/service/produc_service.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';
import 'package:fastfood/layers/domain/repository/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductService service;

  ProductRepositoryImpl(this.service);

  @override
  Future<Either<String, List<ProductEntity>>> getProducts(String query) {
    return service.getProducts(query);
  }
}
