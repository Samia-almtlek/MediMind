import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _keyAvatar = GlobalKey();
  final GlobalKey _keyPersonalData = GlobalKey();
  final GlobalKey _keyMyMedications = GlobalKey();
  final GlobalKey _keyMedicalId = GlobalKey();
  final GlobalKey _keyNotifications = GlobalKey();
  final GlobalKey _keyPrivacy = GlobalKey();
  final GlobalKey _keySupport = GlobalKey();
  final GlobalKey _keyLogout = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTour();
    });
  }

  Future<void> _checkAndShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('profile_tour_seen') ?? false;
    if (seen || !mounted) return;
    _showTutorial();
    await prefs.setBool('profile_tour_seen', true);
  }

  void _showTutorial() {
    final topTargets = <TargetFocus>[];
    final bottomTargets = <TargetFocus>[];

    void addIfVisible({
      required List<TargetFocus> list,
      required String identify,
      required GlobalKey key,
      required String title,
      required String message,
      required ContentAlign align,
    }) {
      if (key.currentContext != null) {
        list.add(_buildTarget(
          identify: identify,
          key: key,
          title: title,
          message: message,
          align: align,
        ));
      }
    }

    addIfVisible(
      list: topTargets,
      identify: 'profile_avatar',
      key: _keyAvatar,
      title: 'Your profile',
      message: 'Tap the camera icon to update your profile photo and personal details.',
      align: ContentAlign.bottom,
    );
    addIfVisible(
      list: topTargets,
      identify: 'profile_personal_data',
      key: _keyPersonalData,
      title: 'Personal Data',
      message: 'Open this item to edit your profile information.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: topTargets,
      identify: 'profile_my_meds',
      key: _keyMyMedications,
      title: 'My Medications',
      message: 'Track your active treatments and medication overview.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: topTargets,
      identify: 'profile_medical_id',
      key: _keyMedicalId,
      title: 'Medical ID',
      message: 'Store emergency information like blood type and contact details.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: topTargets,
      identify: 'profile_notifications',
      key: _keyNotifications,
      title: 'Notifications',
      message: 'Enable or disable reminder alerts from this section.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: bottomTargets,
      identify: 'profile_privacy',
      key: _keyPrivacy,
      title: 'Privacy & Data',
      message: 'Access GDPR settings and export/report privacy controls.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: bottomTargets,
      identify: 'profile_support',
      key: _keySupport,
      title: 'Support',
      message: 'Get help, FAQ answers, and contact options.',
      align: ContentAlign.top,
    );
    addIfVisible(
      list: bottomTargets,
      identify: 'profile_logout',
      key: _keyLogout,
      title: 'Logout',
      message: 'Sign out safely from your account.',
      align: ContentAlign.top,
    );

    if (topTargets.isEmpty) return;

    Future<void> showBottomTour() async {
      if (bottomTargets.isEmpty || !mounted) return;
      await _scrollToKey(_keyPrivacy);
      if (!mounted) return;
      TutorialCoachMark(
        targets: bottomTargets,
        colorShadow: AppColors.primaryBlue,
        opacityShadow: 0.78,
        alignSkip: Alignment.topLeft,
        skipWidget: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 14, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightTeal.withOpacity(0.9)),
            ),
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        paddingFocus: 8,
      ).show(context: context);
    }

    TutorialCoachMark(
      targets: topTargets,
      colorShadow: AppColors.primaryBlue,
      opacityShadow: 0.78,
      alignSkip: Alignment.topLeft,
      skipWidget: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 14, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightTeal.withOpacity(0.9)),
          ),
          child: const Text(
            'SKIP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      paddingFocus: 8,
      onFinish: showBottomTour,
    ).show(context: context);
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final contextForKey = key.currentContext;
    if (contextForKey == null || !_scrollController.hasClients) return;

    await Scrollable.ensureVisible(
      contextForKey,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.18,
    );
  }

  TargetFocus _buildTarget({
    required String identify,
    required GlobalKey key,
    required String title,
    required String message,
    required ContentAlign align,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: key,
      contents: [
        TargetContent(
          align: align,
          builder: (_, __) => Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.iconGrey.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightTeal.withOpacity(0.75)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Function to refresh user data after editing profile
  Future<void> _refreshUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // forces firebase to refresh the user data
      setState(() {
        // the build() method will automatically use the updated user data from FirebaseAuth.instance.currentUser
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        controller: _scrollController,
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
                        key: _keyAvatar,
                        radius: 55,
                        backgroundColor: AppColors.lightTeal.withOpacity(0.5),
                        backgroundImage: user?.photoURL != null
                          ? (user!.photoURL!.startsWith('http')
                            ? NetworkImage(user.photoURL!)
                            : FileImage(File(user.photoURL!))
                              as ImageProvider)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person,
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
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen()),
                            );
                            await _refreshUser(); // Trigger rebuild to show updated profile picture
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                size: 20, color: AppColors.iconGrey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // shows displayname of 'User' if its null
                  Text(
                    user?.displayName ?? "MediMind User",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              leadingKey: _keyPersonalData,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
                await _refreshUser();
              },
            ),

            const SizedBox(height: 20),

            // MANAGE HEALTH section
            _buildSectionHeader("Manage Health"),
            _buildProfileItem(
              icon: Icons.health_and_safety_outlined,
              title: "My Medications",
              subtitle: "Track your active treatments",
              leadingKey: _keyMyMedications,
              onTap: () => Navigator.pushNamed(context, '/medications'),
            ),
            _buildProfileItem(
              icon: Icons.medical_information_outlined,
              title: "Medical ID",
              subtitle: "Emergency contact & blood type",
              leadingKey: _keyMedicalId,
              onTap: () => Navigator.pushNamed(context, '/medical_id'),
            ),

            const SizedBox(height: 20),

            // PREFERENCES section
            _buildSectionHeader("Preferences"),
            _buildProfileItem(
              icon: Icons.notifications_none_rounded,
              title: "Notifications",
              subtitle: "Reminders & Alerts",
              leadingKey: _keyNotifications,
              onTap: () => Navigator.pushNamed(context,
                  '/notifications'), // Navigate to the notification settings screen
              trailing: Switch(
                value: _notificationsEnabled,
                activeThumbColor: AppColors.primaryBlue,
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
              leadingKey: _keyPrivacy,
              onTap: () => Navigator.pushNamed(context, '/privacy'),
            ),

            const SizedBox(height: 20),

            // ACCOUNT section
            _buildSectionHeader("Account"),
            _buildProfileItem(
              icon: Icons.help_outline_rounded,
              title: "Support",
              subtitle: "FAQ & Contact us",
              leadingKey: _keySupport,
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(thickness: 0.5),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(Icons.logout_rounded, key: _keyLogout, color: Colors.redAccent),
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
      Key? leadingKey,
      Widget? trailing,
      VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        key: leadingKey,
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
