import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _passwordController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? "";
    _emailController.text = user?.email ?? "";
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
    } catch (_) {
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      // 1. Update the photoURL if a new image was picked
      if (_imageFile != null) {
        // for the actual app the image should be uploaded in Firebase Storage and the returned URL should be saved in FirebaseAuth. But for now we save the local path so the app knows which file to load.
        await user?.updatePhotoURL(_imageFile!.path);
      }

      // 2. Update Display Name
      if (_nameController.text != user?.displayName) {
        await user?.updateDisplayName(_nameController.text);
      }

      if (user != null) {
        final trimmedAge = _ageController.text.trim();
        final parsedAge = int.tryParse(trimmedAge);

        if (trimmedAge.isNotEmpty && (parsedAge == null || parsedAge < 0 || parsedAge > 130)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid age (0-130).")),
          );
          return;
        }

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'age': trimmedAge.isEmpty ? FieldValue.delete() : parsedAge,
        }, SetOptions(merge: true));
      }

      // 3. Forces a reload of the user to ensure the latest data is fetched from Firebase
      await user?.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'requires-recent-login') message = "Please re-login to change sensitive data.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(title: const Text("Edit Profile", style: TextStyle(color: Colors.black))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.lightTeal,
                        backgroundImage: _imageFile != null 
                            ? FileImage(_imageFile!) 
                            : (user?.photoURL != null ? NetworkImage(user!.photoURL!) : null) as ImageProvider?,
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, "Username", Icons.person_outline),
                _buildTextField(_emailController, "Email", Icons.email_outlined, inputType: TextInputType.emailAddress),
                _buildTextField(_ageController, "Age (optional)", Icons.cake_outlined, inputType: TextInputType.number),
                _buildTextField(_passwordController, "New Password (optional)", Icons.lock_outline, isPassword: true),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _updateProfile,
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType inputType = TextInputType.text}) {
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