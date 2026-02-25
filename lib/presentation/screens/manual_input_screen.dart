import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../utils/app_colors.dart';
import 'treatment_duration_screen.dart';
import 'package:medimind/domain/models/medication.dart';

class ManualInputScreen extends StatefulWidget {
  @override
  _ManualInputScreenState createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<String> suggestions = [];

  /// 🔍 Autocomplete search from LOCAL Hive DB
  void searchDrugs(String query) {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    final box = Hive.box<String>('drugs');
    final normalizedQuery = query.toLowerCase().trim();

    final results = box.values
        .where((name) => name.startsWith(normalizedQuery))
        .take(10)
        .toList();

    setState(() {
      suggestions = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manual Input",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Medication Name ----------------
            const Text(
              "Medication Name",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "e.g., Paracetamol"),
              onChanged: searchDrugs,
            ),

            // 📋 Autocomplete suggestions
            ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(suggestions[index]),
                  onTap: () {
                    setState(() {
                      nameController.text = suggestions[index];
                      suggestions = [];
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ---------------- Dosage ----------------
            const Text(
              "Dosage",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(hintText: "e.g., 500 mg"),
            ),

            const SizedBox(height: 20),

            // ---------------- Notes ----------------
            const Text(
              "Notes (Optional)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., Take with food, avoid alcohol...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const Spacer(),

            // ---------------- Next Button ----------------
            SSurfaceButton(
              text: "Next",
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreatmentDurationScreen(
                        medicationName: nameController.text,
                        dosage: dosageController.text,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a medication name"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Reusable Button ----------------
class SSurfaceButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SSurfaceButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          'Next',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
