import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../auth/service/auth_service.dart';
import '../../core/service/tts_service.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  late Box medicalBox;
  bool isEditing = false;
  bool isLoading = false;

  // Medical ID State
  String? selectedBloodType;
  final TextEditingController _allergyController = TextEditingController();
  List<String> allergies = [];

  // Caregiver State
  final TextEditingController _caregiverNameController = TextEditingController();
  final TextEditingController _caregiverEmailController = TextEditingController();
  final TextEditingController _caregiverRelationController = TextEditingController();

  final AuthService _authService = AuthService();
  final List<String> bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  void initState() {
    super.initState();
    medicalBox = Hive.box('medical_id_data');
    _loadInitialData();
  }

  /// 1. Load data scoped to the current User UID
  Future<void> _loadInitialData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final String uid = user.uid;

    // Load local cache first using UID-specific keys to avoid seeing old user data
    setState(() {
      selectedBloodType = medicalBox.get('${uid}_bloodType');
      allergies = List<String>.from(medicalBox.get('${uid}_allergies', defaultValue: []));
      
      // Clear controllers to ensure old user text is not visible
      _caregiverNameController.clear();
      _caregiverEmailController.clear();
      _caregiverRelationController.clear();
    });

    setState(() => isLoading = true);

    try {
      // Fetch Parent Document (Medical ID)
      final medicalDoc = await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(uid)
          .get();

      if (medicalDoc.exists) {
        final data = medicalDoc.data()!;
        setState(() {
          selectedBloodType = data['bloodType'];
          allergies = List<String>.from(data['allergies'] ?? []);
        });

        // Update local cache with fresh data scoped to UID
        medicalBox.put('${uid}_bloodType', selectedBloodType);
        medicalBox.put('${uid}_allergies', allergies);
      } else {
        // Reset state if no document exists for this specific user
        setState(() {
          selectedBloodType = null;
          allergies = [];
        });
      }

      // Fetch Sub-collection (Caregiver)
      final caregiverSnap = await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(uid)
          .collection('caregivers')
          .doc('primary_contact')
          .get();

      if (caregiverSnap.exists) {
        final cData = caregiverSnap.data()!;
        setState(() {
          _caregiverNameController.text = cData['name'] ?? '';
          _caregiverEmailController.text = cData['email'] ?? '';
          _caregiverRelationController.text = cData['relation'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// 2. Save Data to Firestore and local Hive (Scoped to UID)
  Future<void> _saveData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    if (_caregiverNameController.text.isEmpty || _caregiverEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Caregiver details are required.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final String uid = user.uid;

      // Step A: Save to Firestore
      await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(uid)
          .set({
        'userId': uid,
        'bloodType': selectedBloodType,
        'allergies': allergies,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(uid)
          .collection('caregivers')
          .doc('primary_contact')
          .set({
        'userId': uid,
        'name': _caregiverNameController.text,
        'email': _caregiverEmailController.text,
        'relation': _caregiverRelationController.text,
        'isActive': true,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Step B: Update Local Hive with UID prefix
      await medicalBox.put('${uid}_bloodType', selectedBloodType);
      await medicalBox.put('${uid}_allergies', allergies);

      setState(() => isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medical ID saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _buildMedicalSummary() {
    final buffer = StringBuffer();
    buffer.writeln("Here is your medical identification information.");
    buffer.writeln(selectedBloodType != null ? "Blood type is $selectedBloodType." : "Blood type is not specified.");
    if (allergies.isNotEmpty) {
      buffer.writeln("Allergies include: ${allergies.join(", ")}.");
    } else {
      buffer.writeln("No allergies listed.");
    }
    if (_caregiverNameController.text.isNotEmpty) {
      buffer.writeln("Emergency contact is ${_caregiverNameController.text}, relation ${_caregiverRelationController.text}.");
    } else {
      buffer.writeln("No emergency contact specified.");
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    TTSService.instance.stopIfSpeaking();
    _allergyController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _caregiverRelationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Medical ID", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppColors.primaryBlue),
            onPressed: () {
              final text = _buildMedicalSummary();
              if (text.trim().isNotEmpty) TTSService.instance.speak(text);
            },
          ),
          if (isLoading)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit, color: AppColors.primaryBlue),
              onPressed: isEditing ? _saveData : () => setState(() => isEditing = true),
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
            const SizedBox(height: 25),
            _sectionTitle("Allergies"),
            _buildAllergySection(),
            const SizedBox(height: 25),
            _sectionTitle("Emergency Contact"),
            _buildCaregiverFields(),
          ],
        ),
      ),
    );
  }

  // UI Helper methods remain largely the same...
  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedBloodType,
      decoration: _inputDecoration("Blood Type", Icons.bloodtype),
      items: bloodTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: isEditing ? (val) => setState(() => selectedBloodType = val) : null,
    );
  }

  Widget _buildAllergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing) ...[
          TextField(
            controller: _allergyController,
            decoration: _inputDecoration("Add allergy", Icons.warning_amber).copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primaryBlue),
                onPressed: () {
                  if (_allergyController.text.trim().isNotEmpty) {
                    setState(() {
                      allergies.add(_allergyController.text.trim());
                      _allergyController.clear();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: allergies.map((a) => Chip(
            label: Text(a),
            onDeleted: isEditing ? () => setState(() => allergies.remove(a)) : null,
            deleteIconColor: Colors.redAccent,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )).toList(),
        ),
        if (allergies.isEmpty && !isEditing)
          const Text("No allergies listed", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCaregiverFields() {
    return Column(
      children: [
        _buildEditField(_caregiverNameController, "Name", Icons.person),
        _buildEditField(_caregiverEmailController, "Email", Icons.email, inputType: TextInputType.emailAddress),
        _buildEditField(_caregiverRelationController, "Relation", Icons.family_restroom),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1.1)),
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: !isEditing,
        fillColor: isEditing ? Colors.transparent : Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      );

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: _inputDecoration(label, icon),
        readOnly: !isEditing,
      ),
    );
  }
}