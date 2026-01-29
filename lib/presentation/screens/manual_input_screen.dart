import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ManualInputScreen extends StatefulWidget {
  @override
  _ManualInputScreenState createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual Input", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Medication Name", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: nameController, decoration: InputDecoration(hintText: "e.g., Paracetamol")),
            SizedBox(height: 20),
            Text("Dosage", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: dosageController, decoration: InputDecoration(hintText: "e.g., 500 mg")),
            Spacer(),
            SSurfaceButton(
              text: "Next",
              onPressed: () {
                // Flow: Hierna zou je naar 'Treatment Duration' gaan
                print("Saving: ${nameController.text}");
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Een simpele herbruikbare knop voor je flow
class SSurfaceButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  SSurfaceButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}