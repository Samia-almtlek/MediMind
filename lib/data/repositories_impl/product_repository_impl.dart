import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirestoreService _firestoreService;

  ProductRepositoryImpl(this._firestoreService);

  @override
  Future<List<ProductEntity>> getAllProducts() async {
    final snapshot = await _firestoreService.products.get();

    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    final query = await _firestoreService.products
        .where('barcode', isEqualTo: barcode)
        .get();

    if (query.docs.isEmpty) return null;

    return ProductModel.fromFirestore(query.docs.first);
  }
}
