import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medimind/auth/presentation/screens/login_screen.dart';

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
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action is permanent. All your medical records and stock data will be erased."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteEverything(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    final box = Hive.box('medical_id_data');
    final bloodType = box.get('bloodType', defaultValue: 'Not set');
    final allergies = box.get('allergies', defaultValue: []);

    // Simulation of data export - in the real app, you'd generate a file or send an email
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 50, color: AppColors.primaryBlue),
            const SizedBox(height: 15),
            const Text("Exporting Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text("A summary of your Medical ID ($bloodType, ${allergies.length} allergies) is being sent to your mailbox."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
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
          _buildPrivacyTile(
            "Personal Data", 
            "Manage your profile information", 
            Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, '/medical_id'), // Stuurt ze naar de edit pagina
          ),
          _buildPrivacyTile(
            "Data Export", 
            "Download your medical history", 
            Icons.download_outlined,
            onTap: () => _exportData(context),
          ),
          _buildPrivacyTile(
            "Delete Account", 
            "Permanently remove your data", 
            Icons.delete_outline, 
            isDestructive: true,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile(String title, String sub, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.primaryBlue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.redAccent : Colors.black)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}