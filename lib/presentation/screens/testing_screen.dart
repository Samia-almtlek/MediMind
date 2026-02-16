import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/profile_service.dart'; // Adjust path if needed

class TestingScreen extends StatefulWidget {
  @override
  _TestingScreenState createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  final ProfileService _service = ProfileService();
  bool _notifsEnabled = true;

  // Helper to show status
  void _showStatus(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MediMind Backend Tester")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildTestCard(
                  title: "1. Add Dummy Medication",
                  icon: Icons.medication,
                  onTap: () async {
                    await _service.addMedication({
                      'name': 'Paracetamol',
                      'dosage': '500mg',
                      'frequency': 'Twice a day',
                    });
                    _showStatus("Medication Added!");
                  },
                ),
                _buildTestCard(
                  title: "2. Update Medical ID",
                  icon: Icons.badge,
                  onTap: () async {
                    await _service.updateMedicalId({
                      'bloodType': 'O+',
                      'allergies': 'Peanuts',
                    });
                    _showStatus("Medical ID Updated!");
                  },
                ),
                _buildTestCard(
                  title: "3. Toggle Notifications",
                  icon: Icons.notifications,
                  trailing: Switch(
                    value: _notifsEnabled,
                    onChanged: (val) async {
                      setState(() => _notifsEnabled = val);
                      await _service.updateNotificationPreference(val);
                      _showStatus("Notifications: $val");
                    },
                  ),
                ),
                _buildTestCard(
                  title: "4. Submit Support Ticket",
                  icon: Icons.support_agent,
                  onTap: () async {
                    await _service.submitSupportTicket(
                        "Test Subject", "Test Message");
                    _showStatus("Ticket Submitted!");
                  },
                ),
              ],
            ),
          ),
          Divider(thickness: 2),
          Text("Live Firestore Medications:",
              style: TextStyle(fontWeight: FontWeight.bold)),

          // --- LIVE DATA PREVIEW ---
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getMedications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] ?? 'Unknown'),
                      subtitle: Text("Dosage: ${data['dosage']}"),
                      leading: Icon(Icons.check_circle, color: Colors.green),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
      {required String title,
      required IconData icon,
      VoidCallback? onTap,
      Widget? trailing}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        onTap: onTap,
        trailing: trailing ?? Icon(Icons.play_arrow, color: Colors.grey),
      ),
    );
  }
}
