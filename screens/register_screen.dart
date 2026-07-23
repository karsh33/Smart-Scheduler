import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String message = '';

  Future<void> register() async {
  setState(() {
    isLoading = true;
    message = '';
  });

  final result = await _authService.register(
    nameController.text.trim(),
    emailController.text.trim(),
    passwordController.text.trim(),
  );

  if (!mounted) return;

  setState(() {
    isLoading = false;
  });

  if (result['success'] == true) {
    SnackbarHelper.showSuccess(context, result['message']);
    Navigator.pop(context);
  } else {
    setState(() {
      message = result['message'] ?? 'Registration failed';
    });
    SnackbarHelper.showError(context, message);
  }
}

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Register to use Smart Scheduler'),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}