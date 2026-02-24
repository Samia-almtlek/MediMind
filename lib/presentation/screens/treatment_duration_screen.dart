import 'package:flutter/material.dart';
import 'package:medimind/utils/global_data.dart';
import '../../utils/app_colors.dart';
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
  final Medication? medicationToEdit;

  const TreatmentDurationScreen({super.key, 
    required this.medicationName,
    required this.dosage,
    this.notes,
    this.medicationToEdit,
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
  List<TimeOfDay> selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data if editing
    if (widget.medicationToEdit != null) {
      final med = widget.medicationToEdit!;
      frequency = int.tryParse(med.frequency.split(" ")[0]) ?? 1;
      
      // Parse times from instructions
      if (med.instructions.contains("Times:")) {
        final timesStr = med.instructions.split("Times:")[1].split(".")[0].trim();
        final times = timesStr.split(", ");
        selectedTimes = times
            .map((t) {
              final parts = t.trim().split(":");
              final hour = int.tryParse(parts[0]) ?? 8;
              final minute = int.tryParse(parts[1].split(" ")[0]) ?? 0;
              return TimeOfDay(hour: hour, minute: minute);
            })
            .toList();
      }
      
      // Calculate duration from start and end dates
      final daysDiff = med.endDate.difference(med.startDate).inDays + 1;
      if (daysDiff == 7) {
        selectedDuration = "7 days";
      } else if (daysDiff == 14) {
        selectedDuration = "14 days";
      } else if (daysDiff == 30) {
        selectedDuration = "30 days";
      } else {
        selectedDuration = "Custom";
        customDays = daysDiff;
      }
    }
  }

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
        title: Text(
          widget.medicationToEdit != null ? "Edit Schedule" : "Schedule Logic",
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildDurationGrid(),
            if (selectedDuration == "Custom") _buildCustomDaysInput(),
            const SizedBox(height: 30),
            const Text(
              "Daily Frequency",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildFrequencyDropdown(),
            const SizedBox(height: 20),
            const Text(
              "Intake Times",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            _buildTimePickerList(),
            const SizedBox(height: 30),
            _buildCenteredSummary(),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 55),
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

                  final String instructionsText =
                      "Times: ${selectedTimes.map((t) => t.format(context)).join(', ')}. Notes: ${widget.notes ?? ''}";

                  if (widget.medicationToEdit != null) {
                    // EDIT MODE: Update existing medication in Firestore
                    final med = widget.medicationToEdit!;
                    await FirebaseFirestore.instance
                        .collection('user_medications')
                        .doc(med.id)
                        .update({
                      'name': widget.medicationName,
                      'dosage': widget.dosage,
                      'frequencyPerDay': frequency,
                      'startDate': startDate,
                      'endDate': calculatedEndDate,
                      'instructions': instructionsText,
                    });

                    // Update local list
                    final index = userAddedMeds.indexWhere((m) => m.id == med.id);
                    if (index != -1) {
                      userAddedMeds[index] = Medication(
                        id: med.id,
                        name: widget.medicationName,
                        dosage: widget.dosage,
                        frequency: "$frequency times per day",
                        time: selectedTimes.isNotEmpty
                            ? selectedTimes[0].format(context)
                            : "8:00 AM",
                        endDate: calculatedEndDate,
                        completedDates: med.completedDates,
                        startDate: startDate,
                        instructions: instructionsText,
                      );
                    }
                  } else {
                    // NEW MEDICATION MODE: Create new
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
                      instructions: instructionsText,
                      isActive: true,
                      aangemaaktViaOCR: false,
                      intakeTimes:
                          selectedTimes.map((t) => t.format(context)).toList(),
                      initialStock: 0,
                      currentStock: 0,
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
                          instructions: instructionsText,
                        ),
                      );
                    }
                  }

                  // 5. Navigate on Success
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuccessScreen(
                          medicationName: widget.medicationName),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving medication: $e")),
                  );
                }
              },
              child: const Text(
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
              style: const TextStyle(fontSize: 18, color: AppColors.primaryBlue),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lightTeal.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.lightTeal),
        ),
        child: Column(
          children: [
            const Text(
              "Schedule Overview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Text("Medication: ${widget.medicationName} (${widget.dosage})"),
            Text("Frequency: $frequency times daily"),
            Text("Duration: $totalDays days"),
            Text(
              "Total Doses: ${totalDays * frequency}",
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Toon notities alleen als ze niet leeg zijn
            if (widget.notes != null && widget.notes!.isNotEmpty) ...[
              const Divider(),
              const Text(
                "Notes:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.notes!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
