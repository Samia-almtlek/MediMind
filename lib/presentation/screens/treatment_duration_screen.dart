import 'package:flutter/material.dart';
import 'package:medimind/utils/global_data.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'success_screen.dart';
import '../../domain/models/medication.dart';
import '../../data/repositories_impl/user_medication_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/database/firestore_service.dart';
import '../../domain/entities/user_medication_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// screen to config the treatment duration and schedule with:
/// - How long the treatment lasts (duration)
/// - How many times per day to take it (frequency)
/// - specific times for each dose
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

  // List of times for each daily dose (length matches frequency)
  List<TimeOfDay> selectedTimes = [TimeOfDay(hour: 8, minute: 0)];

  // Updates the list of intake times when frequency changes
  // logic behind is that it evenly distributes throughout the day

  void _updateTimeSuggestions(int newFrequency) {
    setState(() {
      frequency = newFrequency;
      selectedTimes = [];

      // Calculating the interval between doses
      int interval = (24 / frequency).floor();

      for (int i = 0; i < frequency; i++) {
        selectedTimes.add(
          TimeOfDay(hour: (8 + (i * interval)) % 24, minute: 0),
        );
      }
    });
  }

  //opening a time picker dialog to specify
  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index], // Show current time as default
    );

    // Only update if user didn't cancel
    if (picked != null) {
      setState(() {
        selectedTimes[index] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Text(
              "Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildDurationGrid(),
            if (selectedDuration == "Custom") _buildCustomDaysInput(),
            SizedBox(height: 30),
            Text(
              "Daily Frequency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildFrequencyDropdown(),
            SizedBox(height: 20),
            Text(
              "Intake Times",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTimePickerList(),
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
                // 1. Calculate the total days
                int totalDays = selectedDuration == "Custom"
                    ? customDays
                    : int.parse(selectedDuration.split(' ')[0]);

                DateTime startDate = DateTime.now();
                DateTime calculatedEndDate =
                    startDate.add(Duration(days: totalDays - 1));

                // 2. Access your Repository (Assuming you use a locator or Provider)
                // If you don't use a locator, you'd instantiate it:
                // final repo = UserMedicationRepositoryImpl(FirestoreService());
                final repository =
                    UserMedicationRepositoryImpl(FirestoreService());

                try {
                  // Get current user ID
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "You must be logged in to save medication.")),
                    );
                    return;
                  }
                  final String uid = user.uid;

                  // 3. Create the Entity
                  // Note: Since your DB model seems to store one record per medication "plan",
                  // we save the frequency and instructions together.

                  final newMedication = UserMedicationEntity(
                    id: FirebaseFirestore.instance
                        .collection('user_medications')
                        .doc()
                        .id, // Generate ID
                    userId: uid,
                    productId: "",
                    name: widget.medicationName,
                    dosage: widget.dosage,
                    frequencyPerDay: frequency,
                    startDate: startDate,
                    endDate: calculatedEndDate,
                    instructions:
                        "Times: ${selectedTimes.map((t) => t.format(context)).join(', ')}. Notes: ${widget.notes ?? ''}",
                    isActive: true,
                    aangemaaktViaOCR: false,
                  );

                  // 4. Save to Firestore
                  await repository.addUserMedication(newMedication);

                  for (var time in selectedTimes) {
                    userAddedMeds.add(
                      Medication(
                        name: widget.medicationName,
                        dosage: widget.dosage,
                        frequency: "$frequency times per day",
                        time: time.format(context),
                        endDate: calculatedEndDate,
                        completedDates: [],
                        startDate: startDate,
                        instructions:
                            "Times: ${selectedTimes.map((t) => t.format(context)).join(', ')}. Notes: ${widget.notes ?? ''}",
                      ),
                    );
                  }

                  // Create a medication entry for each selected time

                  // 5. Navigate on Success
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
              child: Text(
                "Confirm & Save",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds chips for selecting treatment duration
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

  // Shows text input when user selects "Custom" duration and allows entering any number of days
  Widget _buildCustomDaysInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: "Enter number of days",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        // Parse input as integer, default to 0 if invalid
        onChanged: (val) => setState(() => customDays = int.tryParse(val) ?? 0),
      ),
    );
  }

  // Dropdown to select how many times per day to take medication
  // Range: 1-5 times daily
  // When changed, automatically suggests evenly distributed times
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

  /// Displays a list of time pickers for each dose number of pickers matches the selected frequency
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

  // Calculates total number of doses (duration × frequency)
  Widget _buildCenteredSummary() {
    //  total days: use customDays if "Custom", otherwise parse from selected option
    int totalDays = selectedDuration == "Custom"
        ? customDays
        : int.parse(selectedDuration.split(' ')[0]);

    return Center(
      child: Container(
        width: double.infinity, // Zorgt voor een mooie uitlijning
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
            Divider(),
            Text("Medication: ${widget.medicationName} (${widget.dosage})"),
            Text("Frequency: $frequency times daily"),
            Text("Duration: $totalDays days"),
            Text(
              "Total Doses: ${totalDays * frequency}",
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Toon notities alleen als ze niet leeg zijn
            if (widget.notes != null && widget.notes!.isNotEmpty) ...[
              Divider(),
              Text(
                "Notes:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.notes!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
