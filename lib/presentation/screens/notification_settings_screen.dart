import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _medicationReminders = true;
  bool _stockAlerts = true;
  bool _aiTips = false;

  TimeOfDay _summaryTime = const TimeOfDay(hour: 8, minute: 0);
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('notification_settings'); // 🔥 CHANGED
    _loadSettings();
  }

  void _loadSettings() {
    final savedTime = _settingsBox.get('summaryTime');
    if (savedTime != null) {
      final parts = savedTime.split(':');
      setState(() {
        _summaryTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _summaryTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _summaryTime) {
      setState(() {
        _summaryTime = picked;
      });
      _settingsBox.put('summaryTime', '${picked.hour}:${picked.minute}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hideSensitive =
        _settingsBox.get('hideSensitive', defaultValue: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text("Notification Settings",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

          // 🔒 NEW LOCK SCREEN TOGGLE
          _buildSwitchTile(
            "Hide Sensitive Content",
            "Hide medication names on lock screen",
            hideSensitive,
            (val) {
              _settingsBox.put('hideSensitive', val);
              setState(() {});
            },
          ),

          const SizedBox(height: 10),
          _sectionTitle("Scheduled Summaries"),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.access_time,
                    color: AppColors.primaryBlue, size: 20),
              ),
              title: const Text("Daily Health Overview",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text("Currently set to: ${_summaryTime.format(context)}"),
              trailing: const Icon(Icons.edit_calendar_outlined,
                  size: 20, color: AppColors.primaryBlue),
              onTap: () => _selectTime(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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