import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../backend/profile_service.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Take the logged in user from firebase auth
    final User? user = FirebaseAuth.instance.currentUser;

    final ProfileService _profileService = ProfileService();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            //profile header (we'll see later if we add a picture for the user or not )
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.lightTeal.withOpacity(0.5),
                        child: Icon(Icons.person,
                            size: 60, color: AppColors.primaryBlue),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt,
                              size: 20, color: AppColors.iconGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // shows displayname of 'User' if its null
                  Text(
                    user?.displayName ?? "MediMind User",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "no-email@medimind.com",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // MANAGE HEALTH section
            _buildSectionHeader("Manage Health"),
            _buildProfileItem(
              icon: Icons.health_and_safety_outlined,
              title: "My Medications",
              subtitle: "Track your active treatments",
              onTap: () => Navigator.pushNamed(context, '/schedule'),
            ),
            _buildProfileItem(
              icon: Icons.medical_information_outlined,
              title: "Medical ID",
              subtitle: "Emergency contact & blood type",
              onTap: () {
                Navigator.pushNamed(context, '/medical-id-edit');
              },
            ),

            const SizedBox(height: 20),

            // PREFERENCES section
            _buildSectionHeader("Preferences"),
            _buildProfileItem(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              subtitle: "Reminders & Alerts",
              trailing: Switch(
                value: true,
                activeColor: AppColors.primaryBlue,
                onChanged: (bool newValue) async {
                  await ProfileService().updateNotificationPreference(newValue);
                },
              ),
            ),
            _buildProfileItem(
              icon: Icons.lock_outline_rounded,
              title: "Privacy & Data",
              subtitle: "GDPR & Security settings",
            ),

            const SizedBox(height: 20),

            // ACCOUNT section
            _buildSectionHeader("Account"),
            _buildProfileItem(
              icon: Icons.help_outline_rounded,
              title: "Support",
              subtitle: "FAQ & Contact us",
              onTap: () async {
                await _profileService.submitSupportTicket(
                    "General Help", "User needs assistance");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Support ticket sent!")),
                );
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(thickness: 0.5),
            ),
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                "Logout",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // After logging out, the AuthGate automatically redirects the user to the Login screen
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper voor sectie-titels
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Verbeterde Profile Item Widget
  Widget _buildProfileItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      onTap: onTap ?? () {},
    );
  }
}
