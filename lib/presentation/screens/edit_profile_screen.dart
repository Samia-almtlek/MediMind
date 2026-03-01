import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
    _loadOptionalAge();
  }

  Future<void> _loadOptionalAge() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final data = doc.data();
      final age = data?['age'];
      if (!mounted || age == null) return;
      _ageController.text = age.toString();
    } catch (_) {}
  }

  Future<void> _updateProfile() async {
    final String newPassword = _newPasswordController.text.trim();
    final String currentPassword = _currentPasswordController.text.trim();

    if (newPassword.isNotEmpty && currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your current password to set a new one.'),
        ),
      );
      return;
    }

    final trimmedAge = _ageController.text.trim();
    final parsedAge = int.tryParse(trimmedAge);
    if (trimmedAge.isNotEmpty && (parsedAge == null || parsedAge < 0 || parsedAge > 130)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age (0-130).')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
   if (newPassword.isNotEmpty) {

  if (user!.providerData.any((p) => p.providerId == 'google.com')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password is managed by Google.'),
      ),
    );
    if (user!.providerData.any((p) => p.providerId == 'google.com')) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Password is managed by Google.'),
    ),
  );
  return; 
}
  } else if (user?.email != null) {

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    if (newPassword == currentPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be different from current password.'),
        ),
      );
      return;
    }

    final credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPassword,
    );

    await user!.reauthenticateWithCredential(credential);
await user!.updatePassword(newPassword);  }
}
     
      if (_imageFile != null) {
        await user?.updatePhotoURL(_imageFile!.path);
      }

      final String newName = _nameController.text.trim();
      if (newName != user?.displayName) {
        await user?.updateDisplayName(newName);
      }

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'fullName': newName,
          'updatedAt': FieldValue.serverTimestamp(),
          'age': trimmedAge.isEmpty ? FieldValue.delete() : parsedAge,
        }, SetOptions(merge: true));
      }

      await user?.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'wrong-password') {
        message = 'The current password you entered is incorrect.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please re-login to change sensitive data.';
      } else if (e.code == 'weak-password') {
        message = 'The new password is too weak.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_nameController, 'Username', Icons.person_outline),
                  _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email_outlined,
                    inputType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    _ageController,
                    'Age (optional)',
                    Icons.cake_outlined,
                    inputType: TextInputType.number,
                  ),
                  const Divider(height: 40),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _currentPasswordController,
                    'Current Password',
                    Icons.lock_reset_outlined,
                    isPassword: true,
                  ),
                  _buildTextField(
                    _newPasswordController,
                    'New Password (optional)',
                    Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _updateProfile,
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
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
