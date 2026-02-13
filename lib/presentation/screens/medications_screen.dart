import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class MedicationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: Text("My Medications", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0.5, iconTheme: IconThemeData(color: Colors.black)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_liquid, size: 80, color: AppColors.primaryBlue.withOpacity(0.3)),
            SizedBox(height: 16),
            Text("No medications added yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () { /* Hier komt later de add-logica */ },
      ),
    );
  }
}