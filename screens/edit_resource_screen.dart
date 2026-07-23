import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class EditResourceScreen extends StatefulWidget {
  final Map resource;
  const EditResourceScreen({super.key, required this.resource});

  @override
  State<EditResourceScreen> createState() => _EditResourceScreenState();
}

class _EditResourceScreenState extends State<EditResourceScreen> {
  late TextEditingController nameController;
  late TextEditingController capacityController;
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController priorityController;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  late String selectedType;
  bool isLoading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.resource['name']);
    capacityController =
        TextEditingController(text: widget.resource['capacity'].toString());
    startController =
        TextEditingController(text: widget.resource['availability_start'].toString().substring(0, 5));
    endController =
        TextEditingController(text: widget.resource['availability_end'].toString().substring(0, 5));
    priorityController =
        TextEditingController(text: widget.resource['priority'].toString());

    selectedType = (widget.resource['type'] ?? 'room').toString().toLowerCase();
  }

  Future<void> updateResource() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final token = await _authService.getToken();

    final response = await _apiService.putRequest(
      '/api/resources/${widget.resource['id']}',
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

    if (response.statusCode == 200) {
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Resource updated successfully');
      Navigator.pop(context);
    } else {
      try {
        final data = jsonDecode(response.body);
        final errorText =
            data['message'] ?? data['error'] ?? 'Failed to update resource';
        setState(() {
          message = errorText;
        });
        if (!mounted) return;
        SnackbarHelper.showError(context, errorText);
      } catch (_) {
        setState(() {
          message = 'Failed to update resource';
        });
        if (!mounted) return;
        SnackbarHelper.showError(context, 'Failed to update resource');
      }
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
        title: const Text('Edit Resource'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Resource Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ['room', 'equipment', 'person'].contains(selectedType)
                    ? selectedType
                    : 'room',
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'room', child: Text('room')),
                  DropdownMenuItem(value: 'equipment', child: Text('equipment')),
                  DropdownMenuItem(value: 'person', child: Text('person')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(labelText: 'Availability Start'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(labelText: 'Availability End'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priorityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(message, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: isLoading ? null : updateResource,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Resource'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}