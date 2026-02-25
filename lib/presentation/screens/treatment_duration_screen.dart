import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import 'success_screen.dart';
import '../../domain/models/medication.dart';

class TreatmentDurationScreen extends StatefulWidget {
  final String medicationName;
  final String dosage;
  final String? notes;
  final Medication? medicationToEdit;
  final bool isFromScanner;

  const TreatmentDurationScreen({
    super.key,
    required this.medicationName,
    required this.dosage,
    this.notes,
    this.medicationToEdit,
    this.isFromScanner = false,
  });

  @override
  _TreatmentDurationScreenState createState() =>
      _TreatmentDurationScreenState();
}

class _TreatmentDurationScreenState extends State<TreatmentDurationScreen> {
  String selectedDuration = "7 days";
  int customDays = 0;
  int frequency = 1;
  List<TimeOfDay> selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void initState() {
    super.initState();
    if (widget.medicationToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final med = widget.medicationToEdit!;
    // Extract frequency (e.g., "3x per day" -> 3)
    frequency = int.tryParse(med.instructions.split(' ')[0]) ?? 1;

    // Parse times from instructions "Times: 8:00 AM, 4:00 PM..."
    if (med.instructions.contains("Times:")) {
      try {
        final timesPart = med.instructions.split("Times: ")[1].split(".")[0];
        final timesArray = timesPart.split(", ");
        selectedTimes = timesArray.map((t) {
          final parts = t.trim().split(" "); // ["8:00", "AM"]
          final timeParts = parts[0].split(":");
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          if (parts[1] == "PM" && hour < 12) hour += 12;
          if (parts[1] == "AM" && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }).toList();
      } catch (e) {
        selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
      }
    }

    final daysDiff = med.endDate.difference(med.startDate).inDays + 1;
    if ([7, 14, 30].contains(daysDiff)) {
      selectedDuration = "$daysDiff days";
    } else {
      selectedDuration = "Custom";
      customDays = daysDiff;
    }
  }

  void _updateTimeSuggestions(int newFrequency) {
    setState(() {
      frequency = newFrequency;
      selectedTimes = [];
      int interval = (24 / frequency).floor();
      for (int i = 0; i < frequency; i++) {
        selectedTimes
            .add(TimeOfDay(hour: (8 + (i * interval)) % 24, minute: 0));
      }
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index],
    );
    if (picked != null) setState(() => selectedTimes[index] = picked);
  }

  Future<void> _saveMedication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int totalDays = selectedDuration == "Custom"
        ? customDays
        : int.parse(selectedDuration.split(' ')[0]);

    DateTime startDate = DateTime.now();
    DateTime endDate = startDate.add(Duration(days: totalDays - 1));

    String formattedTimes =
        selectedTimes.map((t) => t.format(context)).join(', ');
    String instructionsText =
        "Times: $formattedTimes. Notes: ${widget.notes ?? ''}";

    final Map<String, dynamic> data = {
      'userId': user.uid, // Ensures privacy per user
      'name': widget.medicationName,
      'dosage': widget.dosage,
      'frequencyPerDay': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'instructions': instructionsText,
      'completedDoseIds': widget.medicationToEdit?.completedDoseIds ??
          [], // Preserves existing progress
      'isActive': true,
    };

    try {
      if (widget.medicationToEdit != null) {
        await FirebaseFirestore.instance
            .collection('user_medications')
            .doc(widget.medicationToEdit!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('user_medications')
            .add(data);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SuccessScreen(medicationName: widget.medicationName),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.medicationToEdit != null
            ? "Edit Schedule"
            : "Treatment Logic"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Duration",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildDurationGrid(),
            if (selectedDuration == "Custom") _buildCustomDaysInput(),
            const SizedBox(height: 30),
            const Text("Daily Frequency",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildFrequencyDropdown(),
            const SizedBox(height: 20),
            _buildTimePickerList(),
            const SizedBox(height: 30),
            _buildSummaryCard(),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveMedication,
              child: const Text("Confirm & Save",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationGrid() {
    return Wrap(
      spacing: 10,
      children: ["7 days", "14 days", "30 days", "Custom"].map((opt) {
        return ChoiceChip(
          label: Text(opt),
          selected: selectedDuration == opt,
          selectedColor: AppColors.primaryBlue,
          labelStyle: TextStyle(
              color: selectedDuration == opt ? Colors.white : Colors.black),
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
          hintText: "Number of days",
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
      items: [1, 2, 3, 4, 5]
          .map((val) =>
              DropdownMenuItem(value: val, child: Text("$val times per day")))
          .toList(),
      onChanged: (val) => _updateTimeSuggestions(val!),
    );
  }

  Widget _buildTimePickerList() {
    return Column(
      children: List.generate(frequency, (index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text("Dose ${index + 1}"),
          trailing: TextButton(
            onPressed: () => _selectTime(index),
            child: Text(selectedTimes[index].format(context),
                style: const TextStyle(
                    fontSize: 18, color: AppColors.primaryBlue)),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard() {
    int totalDays = selectedDuration == "Custom"
        ? customDays
        : int.parse(selectedDuration.split(' ')[0]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightTeal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.lightTeal),
      ),
      child: Column(
        children: [
          const Text("Schedule Overview",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Text("${widget.medicationName} - ${widget.dosage}"),
          Text("Total Doses: ${totalDays * frequency}"),
        ],
      ),
    );
  }
}
