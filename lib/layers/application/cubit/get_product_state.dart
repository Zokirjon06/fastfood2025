part of 'get_product_cubit.dart';

enum ProductStatus { initial, loading, success, failed }

class ProductState extends Equatable {
  const ProductState({
    this.status = ProductStatus.initial,
    this.error,
    this.products = const [],
  });

  final ProductStatus status;
  final String? error;
  final List<ProductEntity> products;

  ProductState copyWith({
    ProductStatus? status,
    String? error,
    List<ProductEntity>? products,
  }) {
    return ProductState(
      status: status ?? this.status,
      error: error ?? this.error,
      products: products ?? this.products,
    );
  }

  @override
  List<Object?> get props => [status, error, products];
}
