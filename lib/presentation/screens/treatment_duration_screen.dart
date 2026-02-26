import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'success_screen.dart';
import '../../data/repositories_impl/user_medication_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/user_medication_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../service/notifications/dose_generation_service.dart';
import '../../core/widgets/speaker_button.dart';

class TreatmentDurationScreen extends StatefulWidget {
  final String medicationName;
  final String dosage;
  final String? notes;

  TreatmentDurationScreen({
    required this.medicationName,
    required this.dosage,
    this.notes,
  });

  @override
  _TreatmentDurationScreenState createState() =>
      _TreatmentDurationScreenState();
}

class _TreatmentDurationScreenState extends State<TreatmentDurationScreen> {
  String selectedDuration = "7 days";

  int customDays = 0;
  int frequency = 1;
  int? currentStock; // 🆕 STOCK

  List<TimeOfDay> selectedTimes = [TimeOfDay(hour: 8, minute: 0)];

  void _updateTimeSuggestions(int newFrequency) {
    setState(() {
      frequency = newFrequency;
      selectedTimes = [];
      int interval = (24 / frequency).floor();

      for (int i = 0; i < frequency; i++) {
        selectedTimes.add(
          TimeOfDay(hour: (8 + (i * interval)) % 24, minute: 0),
        );
      }
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index],
    );

    if (picked != null) {
      setState(() {
        selectedTimes[index] = picked;
      });
    }
  }

  String _buildTreatmentSummary() {
    int totalDays = selectedDuration == "Custom"
        ? customDays
        : int.parse(selectedDuration.split(' ')[0]);

    String summary = "Treatment plan for ${widget.medicationName}. "
        "Dosage ${widget.dosage}. "
        "$frequency times per day. "
        "For $totalDays days. "
        "Total doses ${totalDays * frequency}. ";

    if (widget.notes != null && widget.notes!.isNotEmpty) {
      summary += "Notes: ${widget.notes}.";
    }

    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text("Schedule Logic", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Duration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildDurationGrid(),
            if (selectedDuration == "Custom") _buildCustomDaysInput(),

            SizedBox(height: 30),

            Text("Daily Frequency",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildFrequencyDropdown(),

            SizedBox(height: 20),

            Text("Intake Times",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            _buildTimePickerList(),

            SizedBox(height: 30),

            // 🆕 STOCK INPUT
            Text("Current Stock",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "How many tablets do you currently have?",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                setState(() {
                  currentStock = int.tryParse(val);
                });
              },
            ),

            SizedBox(height: 30),

            _buildCenteredSummary(),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                int totalDays = selectedDuration == "Custom"
                    ? customDays
                    : int.parse(selectedDuration.split(' ')[0]);

                DateTime startDate = DateTime.now();
                DateTime calculatedEndDate =
                    startDate.add(Duration(days: totalDays - 1));

                final repository =
                    UserMedicationRepositoryImpl(FirestoreService());

                try {
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You must be logged in to save medication.")),
                    );
                    return;
                  }

                  if (currentStock == null || currentStock! <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Please enter the number of tablets you have."),
                      ),
                    );
                    return;
                  }

                  final String uid = user.uid;

                  final newMedication = UserMedicationEntity(
                    id: FirebaseFirestore.instance
                        .collection('user_medications')
                        .doc()
                        .id,
                    userId: uid,
                    productId: "",
                    name: widget.medicationName,
                    dosage: widget.dosage,
                    frequencyPerDay: frequency,
                    startDate: startDate,
                    endDate: calculatedEndDate,
                    instructions: widget.notes,
                    intakeTimes: selectedTimes
                        .map((t) =>
                            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}")
                        .toList(),
                    isActive: true,
                    aangemaaktViaOCR: false,

                    // 🆕 STOCK VALUES
                    initialStock: currentStock!,
                    currentStock: currentStock!,
                    lowStockThresholdDays: 3,
                    lastStockAlertAt: null,
                  );

                  await repository.addUserMedication(newMedication);

                  final generator = DoseGenerationService();
                  await generator.generateDoses(newMedication);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SuccessScreen(medicationName: widget.medicationName),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving medication: $e")),
                  );
                }
              },
              child: Text("Confirm & Save",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationGrid() {
    List<String> options = ["7 days", "14 days", "30 days", "Custom"];
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        bool isSelected = selectedDuration == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          selectedColor: AppColors.primaryBlue,
          onSelected: (val) => setState(() => selectedDuration = opt),
        );
      }).toList(),
    );
  }

  Widget _buildCustomDaysInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Enter number of days",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (val) => setState(() => customDays = int.tryParse(val) ?? 0),
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButton<int>(
      value: frequency,
      isExpanded: true,
      items: [1, 2, 3, 4, 5].map((int val) {
        return DropdownMenuItem<int>(
          value: val,
          child: Text("$val times per day"),
        );
      }).toList(),
      onChanged: (val) => _updateTimeSuggestions(val!),
    );
  }

  Widget _buildTimePickerList() {
    return Column(
      children: List.generate(frequency, (index) {
        return ListTile(
          title: Text("Dose ${index + 1}"),
          trailing: TextButton(
            onPressed: () => _selectTime(index),
            child: Text(
              selectedTimes[index].format(context),
              style: TextStyle(fontSize: 18, color: AppColors.primaryBlue),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCenteredSummary() {
    int totalDays = selectedDuration == "Custom"
        ? customDays
        : int.parse(selectedDuration.split(' ')[0]);

    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightTeal.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.lightTeal),
        ),
        child: Column(
          children: [
            Text(
              "Schedule Overview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SpeakerButton(
              text: _buildTreatmentSummary(),
              size: 22,
              color: AppColors.primaryBlue,
            ),
            Divider(),
            Text("Medication: ${widget.medicationName} (${widget.dosage})"),
            Text("Frequency: $frequency times daily"),
            Text("Duration: $totalDays days"),
            Text("Total Doses: ${totalDays * frequency}",
                style: TextStyle(
                    color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
