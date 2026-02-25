import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // New Controllers for Password logic
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "";
    _emailController.text = user?.email ?? "";
  }

  Future<void> _updateProfile() async {
    final String newPassword = _newPasswordController.text.trim();
    final String currentPassword = _currentPasswordController.text.trim();

    // Validation: If they typed a new password, they MUST provide the current one
    if (newPassword.isNotEmpty && currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please enter your current password to set a new one.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Re-authenticate if password change is requested
      if (newPassword.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPassword,
        );

        // This validates the old password
        await user?.reauthenticateWithCredential(credential);
        // This sets the new password
        await user?.updatePassword(newPassword);
      }

      // 2. Update the photoURL if a new image was picked
      if (_imageFile != null) {
        await user?.updatePhotoURL(_imageFile!.path);
      }

      // 3. Update Display Name
      final String newName = _nameController.text.trim();
      if (newName != user?.displayName) {
        await user?.updateDisplayName(newName);
      }

      // 4. Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'fullName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await user?.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'wrong-password') {
        message = "The current password you entered is incorrect.";
      } else if (e.code == 'requires-recent-login') {
        message = "Please re-login to change sensitive data.";
      } else if (e.code == 'weak-password') {
        message = "The new password is too weak.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
          title: const Text("Edit Profile",
              style: TextStyle(color: Colors.black))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Added scroll view to prevent overflow with keyboard
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.lightTeal,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null) as ImageProvider?,
                      child: _imageFile == null && user?.photoURL == null
                          ? const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _nameController, "Username", Icons.person_outline),
                  _buildTextField(
                      _emailController, "Email", Icons.email_outlined,
                      inputType: TextInputType.emailAddress),

                  const Divider(height: 40),
                  const Text("Change Password",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // NEW: Current Password Field
                  _buildTextField(_currentPasswordController,
                      "Current Password", Icons.lock_reset_outlined,
                      isPassword: true),

                  // NEW: New Password Field
                  _buildTextField(_newPasswordController, "New Password",
                      Icons.lock_outline,
                      isPassword: true),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _updateProfile,
                    child: const Text("Save Changes",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
