import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _deleteEverything(BuildContext context) async {
    // delete all local data in Hive
    await Hive.box<String>('drugs').clear();
    await Hive.box('medical_id_data').clear();
    await Hive.box<Map>('medication_stock').clear();

    // delete Firebase account (this will also trigger AuthGate to redirect to login)
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      // AuthGate will automatically redirect to login screen after account deletion
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please re-login to delete your account.")),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action is permanent. All your medical records and stock data will be erased."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _deleteEverything(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Privacy & Data", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPrivacyTile("Personal Data", "Manage your profile information", Icons.person_outline),
          _buildPrivacyTile("Data Export", "Download your medical history", Icons.download_outlined),
          _buildPrivacyTile("Delete Account", "Permanently remove your data", Icons.delete_outline, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(String title, String sub, IconData icon, {bool isDestructive = false}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.primaryBlue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.redAccent : Colors.black)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}