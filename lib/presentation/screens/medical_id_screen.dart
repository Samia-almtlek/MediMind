import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class MedicalIdScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: Text("Medical ID", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0.5, iconTheme: IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoCard("Blood Type", "A+ (Example)", Icons.bloodtype),
            _buildInfoCard("Allergies", "Penicillin, Peanuts", Icons.warning_amber),
            _buildInfoCard("Emergency Contact", "+32 489 00 00 00", Icons.phone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}