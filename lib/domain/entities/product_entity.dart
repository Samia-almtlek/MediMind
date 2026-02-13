class ProductEntity {
  final String id;
  final String name;
  final String dosage;
  final String barcode;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.dosage,
    required this.barcode,
    this.description,
    this.imageUrl,
    this.createdAt,
  });
}
