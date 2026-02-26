import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'manual_input_screen.dart';
import 'package:medimind/presentation/screens/scan_barcode_screen.dart';

//Screen that presents two options for adding medication (manual or throufgh scanning)
class AddChoiceScreen extends StatelessWidget {
  const AddChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Medication", style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              "Choose how to add your medication",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.iconGrey,
              ),
            ),
            const SizedBox(height: 30),
            // manual input option
            _buildOptionCard(
              context,
              title: "Manual Input",
              subtitle: "Enter medication details step-by-step manually.",
              icon: Icons.edit_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ManualInputScreen())),
            ),
            const SizedBox(height: 20),
            //  scanning option
            _buildOptionCard(
              context,
              title: "Scan barcode",
              subtitle:
                  "Use your camera to scan details from a physical label.",
              icon: Icons.document_scanner_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ScanBarcodeScreen())),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.lightTeal.withOpacity(0.2),
          border: Border.all(color: AppColors.lightTeal.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.lightTeal),
              ),
              child: Icon(icon, size: 34, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.iconGrey.withOpacity(0.85))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Tap to continue",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
