import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class TreatmentDurationScreen extends StatefulWidget {
  @override
  _TreatmentDurationScreenState createState() => _TreatmentDurationScreenState();
}

class _TreatmentDurationScreenState extends State<TreatmentDurationScreen> {
  String selectedDuration = "14 days";
  String frequency = "2 times per day";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Treatment Duration", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Duration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildDurationGrid(),
            SizedBox(height: 30),
            Text("Daily Frequency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildFrequencyDropdown(),
            SizedBox(height: 20),
            _buildSummaryCard(),
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // next steps to save the schedule would go here
                print("Schedule Created");
              },
              child: Text("Create Schedule", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


}