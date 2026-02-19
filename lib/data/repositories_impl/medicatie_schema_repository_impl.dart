import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/medicatie_schema_entity.dart';
import '../../domain/repositories/medicatie_schema_repository.dart';
import '../models/medicatie_schema_model.dart';

class MedicatieSchemaRepositoryImpl
    implements MedicatieSchemaRepository {

  final FirestoreService _firestoreService;

  MedicatieSchemaRepositoryImpl(this._firestoreService);

  @override
  Future<List<MedicatieSchemaEntity>> getSchemasByMedication(
      String userMedicationId) async {

    final snapshot = await _firestoreService.medicatieSchema
        .where('userMedicationId', isEqualTo: userMedicationId)
        .get();

    return snapshot.docs
        .map((doc) =>
            MedicatieSchemaModel.fromFirestore(
                doc))
        .toList();
  }

  @override
  Future<void> createSchema(
      MedicatieSchemaEntity schema) async {

    final model =
        MedicatieSchemaModel.fromEntity(schema);

    await _firestoreService.medicatieSchema
        .add(model.toFirestore());
  }

  @override
  Future<void> updateSchema(
      MedicatieSchemaEntity schema) async {

    final model =
        MedicatieSchemaModel.fromEntity(schema);

    await _firestoreService.medicatieSchema
        .doc(schema.id)
        .update(model.toFirestore());
  }

  @override
  Future<void> deleteSchema(String schemaId) async {
    await _firestoreService.medicatieSchema
        .doc(schemaId)
        .delete();
  }
}
