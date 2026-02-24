import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/app_colors.dart';
import '../../auth/service/auth_service.dart';

import '../../service/database/firestore_service.dart';
import '../../data/repositories_impl/caregiver_repository_impl.dart';
import '../../domain/entities/caregiver_entity.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  late Box medicalBox;
  bool isEditing = false;

  // ==========================
  // MEDICAL ID CONTROLLERS
  // ==========================
  String? selectedBloodType;
  final TextEditingController _allergyController = TextEditingController();
  List<String> allergies = [];

  // ==========================
  // CAREGIVER CONTROLLERS
  // ==========================
  final TextEditingController _caregiverNameController = TextEditingController();
  final TextEditingController _caregiverEmailController = TextEditingController();
  final TextEditingController _caregiverRelationController = TextEditingController();

  // ==========================
  // SERVICES
  // ==========================
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late final CaregiverRepositoryImpl _caregiverRepository;

  final List<String> bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  void initState() {
    super.initState();
    medicalBox = Hive.box('medical_id_data');
    _caregiverRepository = CaregiverRepositoryImpl(_firestoreService);
    _loadSavedData();
    _loadCaregiverFromFirestore();
  }

  // ==========================
  // LOAD LOCAL DATA
  // ==========================
  void _loadSavedData() {
    setState(() {
      selectedBloodType = medicalBox.get('bloodType');
      allergies = List<String>.from(
          medicalBox.get('allergies', defaultValue: []));
    });
  }

  // ==========================
  // LOAD CAREGIVER FROM FIRESTORE
  // ==========================
  Future<void> _loadCaregiverFromFirestore() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final snapshot = await _firestoreService.caregivers
        .where('userId', isEqualTo: user.uid)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data()!;
      setState(() {
        _caregiverNameController.text = data['name'] ?? '';
        _caregiverEmailController.text = data['email'] ?? '';
        _caregiverRelationController.text = data['relation'] ?? '';
      });
    }
  }

  // ==========================
  // SAVE DATA
  // ==========================
  Future<void> _saveData() async {

    // Caregiver required
    if (_caregiverNameController.text.isEmpty ||
        _caregiverEmailController.text.isEmpty ||
        _caregiverRelationController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caregiver is required.")),
      );
      return;
    }

    // Save Medical ID locally
    medicalBox.putAll({
      'bloodType': selectedBloodType,
      'allergies': allergies,
    });

    // Save / Update Caregiver in Firestore
    final user = _authService.currentUser;

    if (user != null) {
      final caregiver = CaregiverEntity(
        id: user.uid,
        userId: user.uid,
        name: _caregiverNameController.text,
        email: _caregiverEmailController.text,
        relation: _caregiverRelationController.text,
        isActive: true,
        addedAt: DateTime.now(),
      );

      await _caregiverRepository.addCaregiver(caregiver);
    }

    setState(() => isEditing = false);
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Medical ID",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit,
                color: AppColors.primaryBlue),
            onPressed: isEditing
                ? _saveData
                : () => setState(() => isEditing = true),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Core Information"),
            _buildBloodTypeDropdown(),
            const SizedBox(height: 20),
            _sectionTitle("Allergies"),
            _buildAllergyInput(),
            const SizedBox(height: 20),
            _sectionTitle("Contact person (Required)"),
            _buildCaregiverFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBloodType,
      decoration: _inputDecoration("Blood Type", Icons.bloodtype),
      items: bloodTypes
          .map((type) =>
              DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: isEditing
          ? (val) => setState(() => selectedBloodType = val)
          : null,
    );
  }

  Widget _buildAllergyInput() {
    return Column(
      children: [
        if (isEditing)
          TextField(
            controller: _allergyController,
            decoration: _inputDecoration(
                    "Add allergy and press enter",
                    Icons.warning_amber)
                .copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  if (_allergyController.text.isNotEmpty) {
                    setState(() {
                      allergies.add(_allergyController.text);
                      _allergyController.clear();
                    });
                  }
                },
              ),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  allergies.add(val);
                  _allergyController.clear();
                });
              }
            },
          ),
        Wrap(
          spacing: 8,
          children: allergies
              .map((a) => Chip(
                    label: Text(a),
                    onDeleted: isEditing
                        ? () => setState(() => allergies.remove(a))
                        : null,
                    backgroundColor:
                        AppColors.primaryBlue.withOpacity(0.1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCaregiverFields() {
    return Column(
      children: [
        _buildEditField(
            _caregiverNameController, "Caregiver Name", Icons.person),
        _buildEditField(
            _caregiverEmailController, "Caregiver Email", Icons.email,
            inputType: TextInputType.emailAddress),
        _buildEditField(
            _caregiverRelationController,
            "Relation (e.g. Daughter, Son)",
            Icons.family_restroom),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
      );

  InputDecoration _inputDecoration(
          String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15)),
        enabled: isEditing,
      );

  Widget _buildEditField(
      TextEditingController controller,
      String label,
      IconData icon,
      {TextInputType inputType =
          TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration:
            _inputDecoration(label, icon),
        readOnly: !isEditing,
      ),
    );
  }
}