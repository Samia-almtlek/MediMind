import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/app_colors.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  late Box medicationBox;
  List<Map<String, dynamic>> _myMedications = [];

  // Controllers for the add medication form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    medicationBox = Hive.box('medication_stock');
    _loadMedications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  // Loading the meds from Hive and update the state
  void _loadMedications() {
    final rawData = medicationBox.get('items', defaultValue: []);
    setState(() {
      _myMedications = List<Map<String, dynamic>>.from(
        rawData.map((item) => Map<String, dynamic>.from(item)),
      );
    });
  }

  // Save the list on Hive
  void _saveToHive() {
    medicationBox.put('items', _myMedications);
  }

  void _removeMedicationAt(int index) {
    setState(() {
      _myMedications.removeAt(index);
      _saveToHive();
    });
  }

  void _showAddMedicationSheet() {
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Add Medication Stock",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (errorMessage != null) _buildErrorBadge(errorMessage!),
                _buildTextField(_nameController, "Medication Name", Icons.medication),
                _buildTextField(
                  _dosageController,
                  "Dosage (e.g. 500mg)",
                  Icons.monitor_weight_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _stockController,
                        "Current Stock",
                        Icons.inventory_2_outlined,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _maxController,
                        "Total in Pack",
                        Icons.format_list_numbered,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) {
                      setModalState(
                        () => errorMessage = "Medication name is required",
                      );
                      return;
                    }
                    if (_stockController.text.trim().isEmpty) {
                      setModalState(
                        () => errorMessage = "Current stock is required",
                      );
                      return;
                    }
                    if (_maxController.text.trim().isEmpty) {
                      setModalState(
                        () => errorMessage = "Total in pack is required",
                      );
                      return;
                    }

                    setState(() {
                      _myMedications.add({
                        "name": _nameController.text.trim(),
                        "dosage": _dosageController.text.trim(),
                        "currentStock": int.tryParse(_stockController.text) ?? 0,
                        "maxStock": int.tryParse(_maxController.text) ?? 1,
                      });
                      _saveToHive();
                    });

                    _nameController.clear();
                    _dosageController.clear();
                    _stockController.clear();
                    _maxController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add to Cabinet",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBadge(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50]?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("My Cabinet", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _myMedications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _myMedications.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key('${_myMedications[index]['name']}_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeMedicationAt(index),
                  child: _buildMedicineCard(_myMedications[index], index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicationSheet,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Stock", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Your cabinet is empty", style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text("Add your medication to track stock", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med, int index) {
    final int currentStock = (med['currentStock'] as int?) ?? 0;
    final int maxStock = ((med['maxStock'] as int?) ?? 1).clamp(1, 999999);
    final double progress = (currentStock / maxStock).clamp(0.0, 1.0);
    Color statusColor = progress < 0.2 ? Colors.redAccent : (progress < 0.5 ? Colors.orangeAccent : AppColors.primaryBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.medication, color: statusColor)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(med['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(med['dosage'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ])),
              Text("$currentStock/$maxStock", style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
              IconButton(
                onPressed: () => _removeMedicationAt(index),
                icon: const Icon(Icons.delete_outline),
                color: Colors.redAccent,
                tooltip: 'Delete medication',
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(statusColor))),
        ],
      ),
    );
  }
}