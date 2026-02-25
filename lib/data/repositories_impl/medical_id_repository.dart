import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/medical_id_model.dart';
import 'caregiver_repository_impl.dart';
import '../../data/models/caregiver_model.dart';
class MedicalRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FETCH: Link Caregivers to MedicalId
  Future<MedicalIdModel> getMedicalIdComplete(String medicalId) async {
    // 1. Get the main Medical ID doc
    final doc = await _firestore.collection('medical_ids').doc(medicalId).get();

    // 2. Get the Caregivers from the sub-collection
    final caregiverSnapshot = await _firestore
        .collection('medical_ids')
        .doc(medicalId)
        .collection('caregivers')
        .get();

    final caregivers = caregiverSnapshot.docs
        .map((d) => CaregiverModel.fromFirestore(d))
        .toList();

    // 3. Combine them into the model
    return MedicalIdModel.fromFirestore(doc, caregivers);
  }

  // CREATE: Add a caregiver to the sub-collection
  Future<void> addCaregiverToMedicalId(String medicalId, CaregiverModel caregiver) async {
    await _firestore
        .collection('medical_ids')
        .doc(medicalId)
        .collection('caregivers') // The link happens here
        .add(caregiver.toFirestore());
  }
}