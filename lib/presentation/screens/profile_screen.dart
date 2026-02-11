import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.lightTeal,
              child: Icon(Icons.person, size: 50, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 10),
            Text("User Name", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("user@medimind.com", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),
            
            // Settings List
            _buildProfileItem(Icons.medical_services_outlined, "Medical ID", "Emergency info"),
            _buildProfileItem(Icons.notifications_none, "Notifications", "Reminders & Alerts"),
            _buildProfileItem(Icons.security, "Privacy & Data", "GDPR & Security"),
            _buildProfileItem(Icons.help_outline, "Support", "Contact & FAQ"),
            
            Divider(height: 40),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryBlue),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}