import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.headset_mic_outlined, size: 40, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            const Text("How can we help?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildFAQTile("How do I add a new medicine?"),
            _buildFAQTile("Is my data safe with MediMind?"),
            _buildFAQTile("Can I share my list with my doctor?"),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {},
              child: const Text("Contact Support", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.add, size: 18, color: AppColors.primaryBlue),
      ),
    );
  }
}