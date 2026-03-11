import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' show EmailAuthProvider;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medimind/auth/presentation/screens/login_screen.dart';
import '../../core/widgets/speaker_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/service/tts_service.dart';
import '../../service/pdf_service.dart';
import '../../domain/models/medication.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _deleteEverything(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Delete Firestore Data (Do this while still authenticated)
      // Delete main profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete Medical ID
      await FirebaseFirestore.instance
          .collection('medical_ids')
          .doc(user.uid)
          .delete();

      // Delete User Medications
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('user_medications')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (var doc in medsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete Dose Logs
      final doseSnapshot = await FirebaseFirestore.instance
          .collectionGroup('dose_logs')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (var doc in doseSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Clear Hive (The Error-Proof Way)
      // First, close ALL boxes to prevent "Already Open" or Type errors
      await Hive.close();

      // Now delete the actual files from the phone's storage
      final boxesToDelete = ['drugs', 'medical_id_data', 'medication_stock'];
      for (var boxName in boxesToDelete) {
        await Hive.deleteBoxFromDisk(boxName);
      }

      // 3. Delete Firebase Auth Account LAST
      await user.delete();

      if (!context.mounted) return;

      // 4. Send them back to Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Critical Error during deletion: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Account deletion failed. Please try again.")),
        );
      }
    }
  }

  Future<void> _reauthenticateAndDelete(
      BuildContext context, String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await _deleteEverything(context);
      } on FirebaseAuthException {
        // Add this mounted check to prevent async gap errors
        if (!context.mounted) return;

        String errorMessage = "Incorrect password.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteAccountDialog(
        onConfirm: (password) {
          _reauthenticateAndDelete(context, password);
        },
      ),
    );
  }

  void _showInfoPopup(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SpeakerButton(
              text: content,
              size: 20,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () async {
              await TTSService.instance.stopIfSpeaking();
              Navigator.pop(context);
            },
            child: const Text("Understood"),
          )
        ],
      ),
    );
  }

  Future<List<Medication>> _loadUserMedicationsForReport(String uid) async {
    final snapshotByUser = await FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isEqualTo: uid)
        .get();

    final snapshotLegacyNoUserId = await FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isNull: true)
        .get();

    final mergedDocsById =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in snapshotByUser.docs) {
      mergedDocsById[doc.id] = doc;
    }
    for (final doc in snapshotLegacyNoUserId.docs) {
      mergedDocsById[doc.id] = doc;
    }

    return mergedDocsById.values
        .map((doc) => Medication.fromFirestore(doc))
        .toList();
  }

  Future<void> _exportData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to export your report.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final meds = await _loadUserMedicationsForReport(user.uid);
      await PdfService.generateHealthReport(meds);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Privacy & Data",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: AppColors.primaryBlue),
            onPressed: () {
              TTSService.instance.speak(
                "Privacy and data settings. You can manage your data rights, read the privacy policy, or delete your account.",
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Your Data Rights (GDPR)"),
          _buildPrivacyTile(
            "Right of Access",
            "Download a copy of your medical data",
            Icons.download_outlined,
            onTap: () async => _exportData(context),
          ),
          _buildPrivacyTile(
            "Data Processing",
            "How MediMind handles your health info",
            Icons.security_outlined,
            onTap: () => _showInfoPopup(
                context,
                "Data Processing",
                "📋 HOW WE PROCESS YOUR DATA\n\n"
                    "MediMind is committed to protecting your health information with industry-standard security measures.\n\n"
                    "🔐 Encryption & Security:\n"
                    "• All your medical data is encrypted end-to-end\n"
                    "• Your medication history, medical ID, and allergies are stored securely on your device first\n"
                    "• Data is synced to Firebase Firestore using encrypted connections \n\n"
                    " Local & Cloud Storage:\n"
                    "• Primary storage: Your personal device (via Hive database - completely private)\n"
                    "• Cloud backup: Synced to Firebase for account recovery and cross-device access\n"
                    "• You control what gets synced - nothing is mandatory\n\n"
                    " Data Rights:\n"
                    "• We do NOT sell, trade, or share your health data with third parties\n"
                    "• We do NOT use your data for advertising or marketing\n"
                    "• Your medical information is for YOUR eyes only\n\n"
                    "🤝 Compliance:\n"
                    "• MediMind complies with GDPR, HIPAA principles, and data protection regulations\n"
                    "• You can request a copy of all your data at any time\n"
                    "• You can delete your account and ALL associated data permanently"),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("Legal"),
          _buildPrivacyTile(
            "Privacy Policy",
            "Read our full terms of service",
            Icons.description_outlined,
            onTap: () => _showInfoPopup(
                context,
                "Privacy Policy",
                "📄 PRIVACY POLICY - Last Updated: February 2026\n\n"
                    "1. WHAT DATA WE COLLECT:\n"
                    "• Email address & password (for authentication)\n"
                    "• Display name and profile information\n"
                    "• Medical ID: blood type, allergies, emergency contacts\n"
                    "• Medication history & tracking data\n"
                    "• Profile photo (optional)\n\n"
                    "2. HOW WE USE YOUR DATA:\n"
                    "• To provide medication reminders and tracking\n"
                    "• To display your medical emergency information\n"
                    "• To authenticate your account securely\n"
                    "• To sync your data across devices\n"
                    "• To improve app stability and safety\n\n"
                    "3. WHO HAS ACCESS:\n"
                    "• Only YOU have access to your medical data\n"
                    "• Our servers store encrypted data - we cannot read it\n"
                    "• In case of emergency: You have sole control of medical ID visibility\n"
                    "• No third-party apps or services access your data\n\n"
                    "4. YOUR RIGHTS:\n"
                    "✓ Right to Access: Download all your data\n"
                    "✓ Right to Correction: Update your information\n"
                    "✓ Right to Deletion: Permanently erase everything\n"
                    "✓ Right to Portability: Export your data in standard format\n\n"
                    "5. DATA RETENTION:\n"
                    "• We keep your data as long as your account is active\n"
                    "• Upon deletion request, all data is permanently erased within 30 days\n"
                    "• Backups are automatically deleted after standard retention periods\n\n"
                    "6. CONTACT US:\n"
                    "For privacy concerns, contact: "), //hier gaan we een emailadres zetten?
          ),
          _buildPrivacyTile(
            "Cookie Preferences",
            "Manage local storage settings",
            Icons.cookie_outlined,
            onTap: () => _showInfoPopup(context, "Cookies & Storage",
                "We only use essential local storage to keep your app functional offline."),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader("Account Termination"),
          _buildPrivacyTile(
            "Delete Account",
            "Exercise your right to be forgotten",
            Icons.delete_outline,
            isDestructive: true,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1)),
    );
  }

  Widget _buildPrivacyTile(String title, String sub, IconData icon,
      {bool isDestructive = false, VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? Colors.redAccent : AppColors.primaryBlue),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.redAccent : Colors.black)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const _DeleteAccountDialog({required this.onConfirm});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // The controller is now safely disposed ONLY when the dialog is fully removed
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Right to be Forgotten",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              "Under GDPR, you have the right to have all your data erased permanently."),
          const SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Confirm with password",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            if (_passwordController.text.isNotEmpty) {
              widget.onConfirm(_passwordController.text);
              Navigator.pop(context);
            }
          },
          child: const Text(
            "Delete Everything",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
