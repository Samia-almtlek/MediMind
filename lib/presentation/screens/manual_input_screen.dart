import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'treatment_duration_screen.dart';

class ManualInputScreen extends StatefulWidget {
  @override
  _ManualInputScreenState createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<String> suggestions = [];
  bool isLoading = false;

  /// 🔍 Search drugs from Firestore for autocomplete
  Future<void> searchDrugs(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final snapshot =
        await FirebaseFirestore.instance.collection('drugs').get();

    final results = snapshot.docs
        .map((doc) => doc['name'] as String)
        .where((name) =>
            name.toLowerCase().startsWith(query.toLowerCase()))
        .toList();

    setState(() {
      suggestions = results;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual Input", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Medication Name ----------------
            Text(
              "Medication Name",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: "e.g., Paracetamol"),
              onChanged: (value) {
                searchDrugs(value);
              },
            ),

            // 🔄 Loading indicator
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
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

            SizedBox(height: 20),

            // ---------------- Dosage ----------------
            Text("Dosage", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: dosageController,
              decoration: InputDecoration(hintText: "e.g., 500 mg"),
            ),

            SizedBox(height: 20),

            // ---------------- Notes ----------------
            Text("Notes (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., Take with food, avoid alcohol...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            Spacer(),

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
                    SnackBar(
                        content:
                            Text("Please enter a medication name")),
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

  SSurfaceButton({required this.text, required this.onPressed});

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
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
