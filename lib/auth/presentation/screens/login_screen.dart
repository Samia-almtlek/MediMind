import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for text input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Auth service instance
  final AuthService _authService = AuthService();

  // Loading state
  bool _isLoading = false;
// Controls password visibility
bool _isPasswordVisible = false;

 Future<void> _login() async {
  setState(() => _isLoading = true);

  try {
    final credential = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 🔥 Reload user to refresh verification status
    await credential.user!.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && !refreshedUser.emailVerified) {



  if (!mounted) return;
  setState(() => _isLoading = false);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Email Not Verified"),
      content: const Text(
        "Please verify your email before logging in.",
      ),
      actions: [
    TextButton(
  onPressed: () async {
    Navigator.pop(context); //  Close dialog immediately

    await _authService.resendVerificationEmail();
    await _authService.signOut();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Verification email resent."),
        backgroundColor: Colors.green,
      ),
    );
  },
  child: const Text("Resend Email"),
),

        
        TextButton(
          
            onPressed: () async {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pop(context);
    },
          child: const Text("OK"),
          
        ),
        
      ],
    ),
    
  );

  return;
}


    // If verified → do nothing.
    // AuthGate will automatically redirect to MainScreen.

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }

 if (!mounted) return;
setState(() => _isLoading = false);

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Logo
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "MediMind",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 50),

              // Email Field
              _buildInputField(
                label: "Email Address",
                hint: "Enter your email",
                controller: _emailController,
                isPassword: false,
              ),

              const SizedBox(height: 20),

              // Password Field
              _buildInputField(
                label: "Password",
                hint: "Enter your password",
                controller: _passwordController,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              // Login Button
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Create Account
              TextButton(
                onPressed: () async {
  final result = await Navigator.pushNamed(context, '/signup');

  if (result != null && result is Map) {
    _emailController.text = result["email"] ?? "";
    _passwordController.text = result["password"] ?? "";
  }
},

                child: Text(
                  "Create an account",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
  controller: controller,
  obscureText: isPassword ? !_isPasswordVisible : false,

  // ✅ Better keyboard depending on field type
  keyboardType:
      isPassword ? TextInputType.text : TextInputType.emailAddress,

  // ✅ Better action button on keyboard
  textInputAction:
      isPassword ? TextInputAction.done : TextInputAction.next,

  decoration: InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    suffixIcon: isPassword
        ? IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
        : null,
  ),
),


      ],
    );
  }
}
