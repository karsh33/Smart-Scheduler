import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class CreateResourceScreen extends StatefulWidget {
  const CreateResourceScreen({super.key});

  @override
  State<CreateResourceScreen> createState() => _CreateResourceScreenState();
}

class _CreateResourceScreenState extends State<CreateResourceScreen> {
  final nameController = TextEditingController();
  final capacityController = TextEditingController();
  final startController = TextEditingController(text: '09:00');
  final endController = TextEditingController(text: '18:00');
  final priorityController = TextEditingController(text: '1');

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  String selectedType = 'room';
  bool isLoading = false;
  String message = '';

  Future<void> createResource() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final token = await _authService.getToken();

      final response = await _apiService.postRequest(
        '/api/resources',
        {
          'name': nameController.text.trim(),
          'type': selectedType,
          'capacity': int.tryParse(capacityController.text.trim()) ?? 0,
          'availability_start': startController.text.trim(),
          'availability_end': endController.text.trim(),
          'priority': int.tryParse(priorityController.text.trim()) ?? 1,
        },
        token: token,
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, 'Resource created successfully');
        Navigator.pop(context);
      } else {
        String errorText = 'Failed to create resource';
        try {
          final data = jsonDecode(response.body);
          errorText = data['message'] ?? data['error'] ?? errorText;
        } catch (_) {}
        setState(() {
          message = errorText;
        });
        if (!mounted) return;
        SnackbarHelper.showError(context, errorText);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Exception: $e';
      });
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Exception: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    capacityController.dispose();
    startController.dispose();
    endController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Resource'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Resource Name',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'room', child: Text('room')),
                  DropdownMenuItem(value: 'equipment', child: Text('equipment')),
                  DropdownMenuItem(value: 'person', child: Text('person')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Availability Start (HH:MM)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'Availability End (HH:MM)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priorityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                ),
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : createResource,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Resource'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}