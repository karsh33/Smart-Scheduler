import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'create_meeting_screen.dart';
import 'edit_meeting_screen.dart';
import '../utils/snackbar_helper.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List meetings = [];
  List filteredMeetings = [];
  bool isLoading = true;
  String errorMessage = '';
  int? currentUserId;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMeetings();
    searchController.addListener(applyFilter);
  }

  String safeString(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String formatDate(dynamic raw) {
    if (raw == null) return 'N/A';

    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> fetchMeetings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _authService.getToken();
      final userId = await _authService.getUserIdFromToken();

      final response = await _apiService.getRequest(
        '/api/meetings',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          meetings = data;
          filteredMeetings = data;
          currentUserId = userId;
          isLoading = false;
        });
      } else {
        setState(() {
          meetings = [];
          filteredMeetings = [];
          isLoading = false;
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Exception: $e';
      });
    }
  }

  void applyFilter() {
    final query = searchController.text.toLowerCase().trim();

    setState(() {
      filteredMeetings = meetings.where((meeting) {
        final title = safeString(meeting['title'], fallback: '').toLowerCase();
        final resourceName =
            safeString(meeting['resource_name'], fallback: '').toLowerCase();
        return title.contains(query) || resourceName.contains(query);
      }).toList();
    });
  }

  Future<void> deleteMeeting(int id) async {
  final token = await _authService.getToken();

  final response = await _apiService.deleteRequest(
    '/api/meetings/$id',
    token: token,
  );

  dynamic data = {};
  if (response.body.isNotEmpty) {
    try {
      data = jsonDecode(response.body);
    } catch (_) {}
  }

  if (!mounted) return;

  if (response.statusCode == 200) {
    SnackbarHelper.showSuccess(context, 'Meeting deleted successfully');
  } else {
    SnackbarHelper.showError(
      context,
      data['message'] ?? 'Failed to delete meeting',
    );
  }

  fetchMeetings();
}

  void confirmDelete(int id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteMeeting(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget buildMeetingCard(dynamic meeting) {
    final title = safeString(meeting['title'], fallback: 'Untitled Meeting');
    final resourceName =
        safeString(meeting['resource_name'], fallback: 'Unknown');
    final startTime = formatDate(meeting['start_time']);
    final endTime = formatDate(meeting['end_time']);
    final meetingOwnerId = meeting['created_by'];
    final isMine = currentUserId != null && meetingOwnerId == currentUserId;
    final bookedByLabel = isMine
        ? 'Booked by: You'
        : 'Booked by: Another user';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          'Resource: $resourceName\n'
          'Start: $startTime\n'
          'End: $endTime\n'
          '$bookedByLabel',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditMeetingScreen(meeting: meeting),
                    ),
                  );
                  fetchMeetings();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(
                  meeting['id'],
                  title,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search meetings',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : filteredMeetings.isEmpty
                        ?  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No meetings found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Text(
          'Create or schedule a meeting to see it here',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  )
                        : RefreshIndicator(
                            onRefresh: fetchMeetings,
                            child: ListView.builder(
                              itemCount: filteredMeetings.length,
                              itemBuilder: (context, index) {
                                return buildMeetingCard(filteredMeetings[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMeetingScreen(),
            ),
          );
          fetchMeetings();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
