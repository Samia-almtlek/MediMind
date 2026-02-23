import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/medical_id_model.dart';
import '../../domain/entities/medical_id_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  late Box medicalBox;
  bool isEditing = false;

  // Controllers & State
  BloodType? selectedBloodType;
  final TextEditingController _allergyController = TextEditingController();
  List<String> allergies = [];
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final List<String> bloodTypes = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-"
  ];

  bool isPhoneVerified = false;
  bool isVerifying = false;
  final TextEditingController _otpController = TextEditingController();

  void _startVerification() {
    if (!_isValidPhone(_phoneController.text)) return;

    setState(() => isVerifying = true);

    // Simuleer het versturen van een code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Verification code sent to emergency contact...")),
    );

    _showVerificationDialog();
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the 4-digit code sent to the phone number."),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(hintText: "0000"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // We simuleren dat '1234' de juiste code is
              if (_otpController.text == "1234") {
                setState(() {
                  isPhoneVerified = true;
                  isVerifying = false;
                });
                Navigator.pop(context);
                _saveData(); // Sla op als geverifieerd
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid Code!")));
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    medicalBox = Hive.box('medical_id_data');
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    // 1. Replace this with your actual Auth logic (e.g., FirebaseAuth.instance.currentUser?.uid)
    String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

    try {
      // 2. Fetch the specific document from the 'medical_ids' collection
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        // 3. Convert the Firestore data using our Model
        final medicalData = MedicalId.fromFirestore(doc);

        setState(() {
          selectedBloodType = medicalData.bloodType;
          allergies = medicalData.allergies;
          _contactNameController.text = medicalData.emergencyContact.name;
          _phoneController.text = medicalData.emergencyContact.phone;
          _emailController.text = medicalData.emergencyContact.email;
        });
      }
    } catch (e) {
      debugPrint("Error loading medical ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load data from cloud.")),
      );
    }
  }

  bool _isValidPhone(String phone) {
    // Regex voor E.164 formaat (Internationaal)
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }

  void _saveData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You must be logged in to save your medical ID.")),
      );
      return;
    }
    // 1. Create the model instance
    final medicalData = MedicalId(
      userId: user.uid ?? "unknown_user",
      bloodType: selectedBloodType ?? BloodType.oPositive,
      allergies: allergies,
      emergencyContact: EmergencyContact(
        name: _contactNameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
      ),
    );

    // 2. Save to Firestore (using userId as the document ID)
    await FirebaseFirestore.instance
        .collection('medical_ids')
        .doc(medicalData.userId)
        .set(medicalData.toFirestore());

    setState(() => isEditing = false);
  }

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
            onPressed:
                isEditing ? _saveData : () => setState(() => isEditing = true),
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
            _sectionTitle("Emergency Contact"),
            _buildContactFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<BloodType>(
      value: selectedBloodType,
      decoration: _inputDecoration("Blood Type", Icons.bloodtype),
      items: BloodType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged:
          isEditing ? (val) => setState(() => selectedBloodType = val) : null,
    );
  }

  Widget _buildAllergyInput() {
    return Column(
      children: [
        if (isEditing)
          TextField(
            controller: _allergyController,
            decoration: _inputDecoration(
                    "Add allergy and press enter", Icons.warning_amber)
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
                  }),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty)
                setState(() {
                  allergies.add(val);
                  _allergyController.clear();
                });
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
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        _buildEditField(
            _contactNameController, "Contact Name", Icons.person_outline),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            _buildEditField(
                _phoneController, "Phone (e.g. +32...)", Icons.phone,
                inputType: TextInputType.phone),
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 10),
                child: TextButton(
                  onPressed: isPhoneVerified ? null : _startVerification,
                  child: Text(isPhoneVerified ? "Verified" : "Verify",
                      style: TextStyle(
                          color: isPhoneVerified
                              ? Colors.green
                              : AppColors.primaryBlue)),
                ),
              ),
          ],
        ),
        _buildEditField(_emailController, "Email", Icons.email_outlined,
            inputType: TextInputType.emailAddress),
      ],
    );
  }

  // Helpers
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 5),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
      );

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabled: isEditing,
      );

  Widget _buildEditField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: _inputDecoration(label, icon),
        readOnly: !isEditing,
      ),
    );
  }
}
