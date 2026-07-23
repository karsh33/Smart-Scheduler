import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class EditMeetingScreen extends StatefulWidget {
  final Map meeting;

  const EditMeetingScreen({super.key, required this.meeting});

  @override
  State<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  late TextEditingController titleController;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List resources = [];
  int? selectedResourceId;
  bool isLoading = false;
  String message = '';

  DateTime? startDateTime;
  DateTime? endDateTime;

  DateTime? parseBackendDateTime(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // Normalize common backend formats:
  // "2026-04-26 11:00:00", "2026-04-26T11:00:00", "2026-04-26T11:00:00Z"
  final normalized = s.replaceFirst(' ', 'T').replaceFirst('Z', '');
  return DateTime.parse(normalized);
}
  
  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(text: (widget.meeting['title'] ?? '').toString());

    selectedResourceId = widget.meeting['resource_id'] is int
        ? widget.meeting['resource_id']
        : int.tryParse(widget.meeting['resource_id'].toString());

    startDateTime = parseBackendDateTime(widget.meeting['start_time']);
endDateTime = parseBackendDateTime(widget.meeting['end_time']);

    fetchResources();
  }

  Future<void> fetchResources() async {
    final token = await _authService.getToken();

    final response = await _apiService.getRequest(
      '/api/resources',
      token: token,
    );

    if (response.statusCode == 200) {
      setState(() {
        resources = jsonDecode(response.body);
      });
    }
  }

  Future<DateTime?> pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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

  Future<void> updateMeeting() async {
    if (selectedResourceId == null ||
        startDateTime == null ||
        endDateTime == null ||
        titleController.text.trim().isEmpty) {
      setState(() {
        message = 'All fields are required';
      });
      if (!mounted) return;
      SnackbarHelper.showError(context, 'All fields are required');
      return;
    }

    if (!startDateTime!.isBefore(endDateTime!)) {
      setState(() {
        message = 'Start time must be before end time';
      });
      if (!mounted) return;
      SnackbarHelper.showError(context, 'Start time must be before end time');
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    final token = await _authService.getToken();

    final response = await _apiService.putRequest(
      '/api/meetings/${widget.meeting['id']}',
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

    if (response.statusCode == 200) {
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Meeting updated successfully');
      Navigator.pop(context);
    } else {
      final errorText = data['message'] ?? data['error'] ?? 'Failed to update';
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
    final safeSelectedResource = resources.any(
      (r) => r['id'] == selectedResourceId,
    )
        ? selectedResourceId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Meeting'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Title',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: safeSelectedResource,
                decoration: const InputDecoration(
                  labelText: 'Select Resource',
                ),
                items: resources.map<DropdownMenuItem<int>>((resource) {
                  return DropdownMenuItem<int>(
                    value: resource['id'],
                    child: Text((resource['name'] ?? 'Unknown').toString()),
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
                  final base = startDateTime ?? DateTime.now();
                  final picked = await pickDateTime(base);
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
                  final base =
                      endDateTime ?? DateTime.now().add(const Duration(hours: 1));
                  final picked = await pickDateTime(base);
                  if (picked != null) {
                    setState(() => endDateTime = picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: isLoading ? null : updateMeeting,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}