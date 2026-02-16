import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.dosage,
    required super.barcode,
    super.description,
    super.imageUrl,
    super.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['naam'] ?? '',
      dosage: data['dosering'] ?? '',
      barcode: data['barcode'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'naam': name,
      'dosering': dosage,
      'barcode': barcode,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
    };
  }
}
