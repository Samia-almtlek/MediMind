import 'package:flutter/material.dart';
import 'manual_add_medication_screen.dart';


class AddMedicationMethodScreen extends StatelessWidget {
  const AddMedicationMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MethodCard(
                icon: Icons.edit,
                title: 'Manual Input',
                subtitle:
                    'Enter medication details step-by-step manually.',
               onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ManualAddMedicationScreen(),
    ),
  );
},

              ),
              const SizedBox(height: 20),
              _MethodCard(
                icon: Icons.qr_code_scanner,
                title: 'Scan Prescription (OCR)',
                subtitle:
                    'Use your camera to scan details from a physical prescription label.',
                onTap: () {
                  // TODO: Navigate to OCR Screen ()
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Widget 
class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
