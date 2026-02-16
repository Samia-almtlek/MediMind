import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MedicalIdScreen extends StatelessWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  late Box medicalBox;
  bool isEditing = false;

  // Controllers & State
  String? selectedBloodType;
  final TextEditingController _allergyController = TextEditingController();
  List<String> allergies = [];
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final List<String> bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  void initState() {
    super.initState();
    medicalBox = Hive.box('medical_id_data'); // Zorg dat je deze opent in main.dart
    _loadSavedData();
  }

  void _loadSavedData() {
    setState(() {
      selectedBloodType = medicalBox.get('bloodType');
      allergies = List<String>.from(medicalBox.get('allergies', defaultValue: []));
      _contactNameController.text = medicalBox.get('contactName', defaultValue: '');
      _phoneController.text = medicalBox.get('phone', defaultValue: '');
      _emailController.text = medicalBox.get('email', defaultValue: '');
    });
  }

  bool _isValidPhone(String phone) {
    // Regex voor E.164 format (Internationaal)
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }

  void _saveData() {
    if (!_isValidPhone(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone format. Use +32..."))
      );
      return;
    }

    medicalBox.putAll({
      'bloodType': selectedBloodType,
      'allergies': allergies,
      'contactName': _contactNameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
    });

    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Medical ID", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
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
    return DropdownButtonFormField<String>(
      value: selectedBloodType,
      decoration: _inputDecoration("Blood Type", Icons.bloodtype),
      items: bloodTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: isEditing ? (val) => setState(() => selectedBloodType = val) : null,
    );
  }

  Widget _buildAllergyInput() {
    return Column(
      children: [
        if (isEditing)
          TextField(
            controller: _allergyController,
            decoration: _inputDecoration("Add allergy and press enter", Icons.warning_amber).copyWith(
              suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: () {
                if (_allergyController.text.isNotEmpty) {
                  setState(() {
                    allergies.add(_allergyController.text);
                    _allergyController.clear();
                  });
                }
              }),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) setState(() { allergies.add(val); _allergyController.clear(); });
            },
          ),
        Wrap(
          spacing: 8,
          children: allergies.map((a) => Chip(
            label: Text(a),
            onDeleted: isEditing ? () => setState(() => allergies.remove(a)) : null,
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        _buildEditField(_contactNameController, "Contact Name", Icons.person_outline),
        _buildEditField(_phoneController, "Phone (e.g. +32...)", Icons.phone, inputType: TextInputType.phone),
        _buildEditField(_emailController, "Email", Icons.email_outlined, inputType: TextInputType.emailAddress),
      ],
    );
  }

  // Helpers
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 5),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
  );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label, prefixIcon: Icon(icon, color: AppColors.primaryBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    enabled: isEditing,
  );

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, {TextInputType inputType = TextInputType.text}) {
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
  bool isPhoneVerified = false;
bool isVerifying = false;
final TextEditingController _otpController = TextEditingController();

void _startVerification() {
  if (!_isValidPhone(_phoneController.text)) return;

  setState(() => isVerifying = true);
  
  // Simulate sending OTP to the phone number (in real app, integrate with SMS API or Firebase Phone Auth)
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Verification code sent to emergency contact...")),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            // We simulate verification by accepting "1234" as the correct code for demo purposes
            if (_otpController.text == "1234") {
              setState(() {
                isPhoneVerified = true;
                isVerifying = false;
              });
              Navigator.pop(context);
              _saveData(); // Save the medical ID data after successful verification
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Code!")));
            }
          },
          child: const Text("Verify"),
        ),
      ],
    ),
  );
}
}
