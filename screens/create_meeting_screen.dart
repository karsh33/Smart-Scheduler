import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final titleController = TextEditingController();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List resources = [];
  int? selectedResourceId;
  bool isLoading = false;
  String message = '';

  DateTime? startDateTime;
  DateTime? endDateTime;

  @override
  void initState() {
    super.initState();
    fetchResources();
  }

  Future<void> fetchResources() async {
    final token = await _authService.getToken();

    final response = await _apiService.getRequest(
      '/api/resources',
      token: token,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        resources = data;
        if (resources.isNotEmpty) {
          selectedResourceId = resources[0]['id'];
        }
      });
    }
  }

  Future<DateTime?> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.month}/${dt.day}/${dt.year}  $hour:$minute $ampm';
  }

  String toBackendFormat(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:00';
}

  Future<void> createMeeting() async {
    if (selectedResourceId == null) {
      setState(() => message = 'Please select a resource');
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Please select a resource');
      return;
    }

    if (startDateTime == null || endDateTime == null) {
      setState(() => message = 'Please select start and end time');
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Please select start and end time');
      return;
    }

    if (!startDateTime!.isBefore(endDateTime!)) {
      setState(() => message = 'Start time must be before end time');
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Start time must be before end time');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    final token = await _authService.getToken();

    final response = await _apiService.postRequest(
      '/api/meetings',
      {
        'title': titleController.text.trim(),
        'resource_id': selectedResourceId,
        'start_time': toBackendFormat(startDateTime!),
        'end_time': toBackendFormat(endDateTime!),
      },
      token: token,
    );

    final data = jsonDecode(response.body);

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Meeting created successfully');
      Navigator.pop(context);
    } else {
      final errorText = data['message'] ?? 'Failed to create meeting';
      setState(() {
        message = errorText;
      });
      if (!mounted) return;
      SnackbarHelper.showError(context, errorText);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Meeting Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedResourceId,
                decoration: const InputDecoration(labelText: 'Select Resource'),
                items: resources.map<DropdownMenuItem<int>>((resource) {
                  return DropdownMenuItem<int>(
                    value: resource['id'],
                    child: Text(resource['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedResourceId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.grey.shade200,
                title: const Text('Start Time'),
                subtitle: Text(formatDateTime(startDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await pickDateTime();
                  if (picked != null) {
                    setState(() => startDateTime = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey.shade200,
                title: const Text('End Time'),
                subtitle: Text(formatDateTime(endDateTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await pickDateTime();
                  if (picked != null) {
                    setState(() => endDateTime = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(message, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: isLoading ? null : createMeeting,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}