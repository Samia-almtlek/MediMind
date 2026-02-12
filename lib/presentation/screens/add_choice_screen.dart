import 'package:flutter/material.dart';
import 'package:medimind/presentation/screens/scan_barcode_screen.dart';
import '../../utils/app_colors.dart';
import 'manual_input_screen.dart';

//Screen that presents two options for adding medication (manual or throufgh scanning)
class AddChoiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Add Medication", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // manual input option
            _buildOptionCard(
              context,
              title: "Manual Input",
              subtitle: "Enter medication details step-by-step manually.",
              icon: Icons.edit_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ManualInputScreen())),
            ),
            SizedBox(height: 20),
            //  scanning option

            _buildOptionCard(
              context,
              title: "Scan barcode",
              subtitle:
                  "Use your camera to scan details from a physical label.",
              icon: Icons.document_scanner_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ScanBarcodeScreen())),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a clickable card for each medication input option
  Widget _buildOptionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.primaryBlue),
            SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
