import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _medicationReminders = true;
  bool _stockAlerts = true;
  bool _aiTips = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Notification Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSwitchTile(
            "Medication Reminders", 
            "Get notified when it's time to take your pills", 
            _medicationReminders,
            (val) => setState(() => _medicationReminders = val),
          ),
          _buildSwitchTile(
            "Stock Alerts", 
            "Get notified when your medication is running low", 
            _stockAlerts,
            (val) => setState(() => _stockAlerts = val),
          ),
          _buildSwitchTile(
            "Health & AI Tips", 
            "Receive personalized insights from MediMind", 
            _aiTips,
            (val) => setState(() => _aiTips = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: value,
          activeColor: AppColors.primaryBlue,
          onChanged: onChanged,
        ),
      ),
    );
  }
}