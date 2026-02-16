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
    // Regex voor E.164 formaat (Internationaal)
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