import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fastfood/layers/domain/entity/product_entity.dart';

class ProductService {
  final _productsRef = FirebaseFirestore.instance.collection('products');

 Future<Either<String, List<ProductEntity>>> getProducts(String query) async {
  try {
    // Bosh harfni katta, qolganlarini kichik qilish
    String formattedQuery = '';
    if (query.trim().isNotEmpty) {
      formattedQuery = query.trim();
      formattedQuery = formattedQuery[0].toUpperCase() + formattedQuery.substring(1).toLowerCase();
    }

    final snapshot = await _productsRef
        .where('name', isGreaterThanOrEqualTo: formattedQuery)
        .where('name', isLessThan: formattedQuery + 'z')
        .get();

    final products = snapshot.docs.map((doc) {
      final data = doc.data();
      return ProductEntity.fromJson({...data, 'id': doc.id});
    }).toList();

    return right(products);
  } catch (e) {
    return left('Qidirishda xatolik: ${e.toString()}');
  }
}
}