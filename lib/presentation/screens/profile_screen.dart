import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true; // Placeholder for notification settings

  // Function to refresh user data after editing profile
  void _refreshUser() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Take the logged in user from firebase auth
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "My Profile",
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
            //profile header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.lightTeal.withOpacity(0.5),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Icon(Icons.person,
                                size: 60, color: AppColors.primaryBlue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            // Navigates to the EditProfileScreen and waits for it to pop before refreshing user data
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                            _refreshUser(); // Trigger rebuild to show updated profile picture
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Icon(Icons.camera_alt, size: 20, color: AppColors.iconGrey),
                          ),
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

            // ACCOUNT SETTINGS section
            _buildSectionHeader("Account Settings"),
            _buildProfileItem(
              icon: Icons.person_outline,
              title: "Personal Data",
              subtitle: "Update your personal information",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
                _refreshUser();
              },
            ),

            const SizedBox(height: 20),

            // MANAGE HEALTH section
            _buildSectionHeader("Manage Health"),
            _buildProfileItem(
              icon: Icons.health_and_safety_outlined,
              title: "My Medications",
              subtitle: "Track your active treatments",
              onTap: () => Navigator.pushNamed(context, '/medications'),
            ),
            _buildProfileItem(
              icon: Icons.medical_information_outlined,
              title: "Medical ID",
              subtitle: "Emergency contact & blood type",
              onTap: () => Navigator.pushNamed(context, '/medical_id'),
            ),

            const SizedBox(height: 20),

            // PREFERENCES section
            _buildSectionHeader("Preferences"),
            _buildProfileItem(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              subtitle: "Reminders & Alerts",
              onTap: () => Navigator.pushNamed(context,
                  '/notifications'), // Navigate to the notification settings screen
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _notificationsEnabled = val;
                  });
                },
              ),
            ),
            _buildProfileItem(
              icon: Icons.lock_outline_rounded,
              title: "Privacy & Data",
              subtitle: "GDPR & Security settings",
              onTap: () => Navigator.pushNamed(context, '/privacy'),
            ),

            const SizedBox(height: 20),

            // ACCOUNT section
            _buildSectionHeader("Account"),
            _buildProfileItem(
              icon: Icons.help_outline_rounded,
              title: "Support",
              subtitle: "FAQ & Contact us",
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(thickness: 0.5),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
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

  // Helper for section headers
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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

  // Improved Profile Item Widget
  Widget _buildProfileItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
      onTap: onTap ?? () {},
    );
  }
}
