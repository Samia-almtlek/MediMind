import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'success_screen.dart';

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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SuccessScreen(medicationName: widget.medicationName),
                  ),
                );
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
