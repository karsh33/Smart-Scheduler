import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class OptimizeMeetingScreen extends StatefulWidget {
  const OptimizeMeetingScreen({super.key});

  @override
  State<OptimizeMeetingScreen> createState() => _OptimizeMeetingScreenState();
}

class _OptimizeMeetingScreenState extends State<OptimizeMeetingScreen> {
  final titleController = TextEditingController();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String resultMessage = '';
  DateTime? startDateTime;
  DateTime? endDateTime;
  List suggestions = [];

  Future<DateTime?> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select date & time';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  String formatSuggestionDate(String raw) {
  final normalized = raw.replaceFirst(' ', 'T').replaceFirst('Z', '');
  final dt = DateTime.parse(normalized);
  return DateFormat('MMM d, yyyy • h:mm a').format(dt);
}

  String toBackendFormat(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
      '${two(dt.hour)}:${two(dt.minute)}:00';
}

  Future<void> optimizeMeeting() async {
    if (titleController.text.trim().isEmpty) {
      setState(() {
        resultMessage = 'Please enter a meeting title';
        suggestions = [];
      });
      SnackbarHelper.showError(context, 'Please enter a meeting title');
      return;
    }

    if (startDateTime == null || endDateTime == null) {
      setState(() {
        resultMessage = 'Please select start and end time';
        suggestions = [];
      });
      SnackbarHelper.showError(context, 'Please select start and end time');
      return;
    }

    if (!startDateTime!.isBefore(endDateTime!)) {
      setState(() {
        resultMessage = 'Start time must be before end time';
        suggestions = [];
      });
      SnackbarHelper.showError(context, 'Start time must be before end time');
      return;
    }

    setState(() {
      isLoading = true;
      resultMessage = '';
      suggestions = [];
    });

    try {
      final token = await _authService.getToken();

      final response = await _apiService.postRequest(
        '/api/meetings/optimize',
        {
          'title': titleController.text.trim(),
          'requested_start_time': toBackendFormat(startDateTime!),
          'requested_end_time': toBackendFormat(endDateTime!),
        },
        token: token,
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final room = data['assigned_resource']['name'];
        setState(() {
          resultMessage = 'Meeting scheduled in $room';
          suggestions = [];
        });
        SnackbarHelper.showSuccess(context, 'Meeting scheduled in $room');
      } else {
        setState(() {
          resultMessage = data['message'] ?? data['error'] ?? 'Scheduling failed';
          suggestions = data['suggestions'] ?? [];
        });
        SnackbarHelper.showError(context, resultMessage);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        resultMessage = 'Error: $e';
        suggestions = [];
      });
      SnackbarHelper.showError(context, 'Error: $e');
    }
  }

  Future<void> bookSuggestion(Map suggestion) async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _authService.getToken();

      final response = await _apiService.postRequest(
        '/api/meetings',
        {
          'title': titleController.text.trim(),
          'resource_id': suggestion['resource']['id'],
          'start_time': suggestion['start_time'],
          'end_time': suggestion['end_time'],
        },
        token: token,
      );

      final data = jsonDecode(response.body);

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final room = suggestion['resource']['name'];
        setState(() {
          resultMessage = 'Suggested slot booked in $room';
          suggestions = [];
        });
        SnackbarHelper.showSuccess(context, 'Suggested slot booked in $room');
      } else {
        SnackbarHelper.showError(
          context,
          data['message'] ?? data['error'] ?? 'Failed to book suggestion',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      SnackbarHelper.showError(context, 'Error booking suggestion: $e');
    }
  }

  Widget buildSuggestionCard(Map suggestion) {
    final resource = suggestion['resource'];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.indigo),
        title: Text(resource['name']),
        subtitle: Text(
          'Start: ${formatSuggestionDate(suggestion['start_time'])}\n'
          'End: ${formatSuggestionDate(suggestion['end_time'])}',
        ),
        trailing: ElevatedButton(
          onPressed: isLoading ? null : () => bookSuggestion(suggestion),
          child: const Text('Book'),
        ),
      ),
    );
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
        title: const Text('Smart Schedule Meeting'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Meeting Title'),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: Colors.white,
                title: const Text('Requested Start Time'),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: Colors.white,
                title: const Text('Requested End Time'),
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
              ElevatedButton(
                onPressed: isLoading ? null : optimizeMeeting,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Optimize & Schedule'),
              ),
              const SizedBox(height: 20),
              if (resultMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    resultMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Suggested Alternate Slots',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...suggestions.map((s) => buildSuggestionCard(s)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}