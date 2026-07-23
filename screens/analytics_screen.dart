import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  int totalResources = 0;
  int totalMeetings = 0;
  int totalRooms = 0;
  int totalOtherResources = 0;
  String busiestResource = 'N/A';
  int busiestCount = 0;
  double totalScheduledHours = 0;
  bool isLoading = true;

  Future<void> loadAnalytics() async {
    final token = await _authService.getToken();

    final resourcesResponse =
        await _apiService.getRequest('/api/resources', token: token);
    final meetingsResponse =
        await _apiService.getRequest('/api/meetings', token: token);

    if (resourcesResponse.statusCode == 200 && meetingsResponse.statusCode == 200) {
      final resources = jsonDecode(resourcesResponse.body) as List;
      final meetings = jsonDecode(meetingsResponse.body) as List;

      final resourceCounts = <String, int>{};
      double totalHours = 0;

      for (final meeting in meetings) {
        final resourceName = meeting['resource_name'] ?? 'Unknown';
        resourceCounts[resourceName] = (resourceCounts[resourceName] ?? 0) + 1;

        final start = DateTime.parse(meeting['start_time']);
        final end = DateTime.parse(meeting['end_time']);
        totalHours += end.difference(start).inMinutes / 60.0;
      }

      String topResource = 'N/A';
      int topCount = 0;

      resourceCounts.forEach((key, value) {
        if (value > topCount) {
          topResource = key;
          topCount = value;
        }
      });

      setState(() {
        totalResources = resources.length;
        totalMeetings = meetings.length;
        totalRooms = resources.where((r) => r['type'] == 'room').length;
        totalOtherResources = resources.where((r) => r['type'] != 'room').length;
        busiestResource = topResource;
        busiestCount = topCount;
        totalScheduledHours = totalHours;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.white),
          const SizedBox(height: 10),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  statCard('Total Resources', '$totalResources', Icons.storage, const Color(0xFF4F46E5)),
                  statCard('Total Meetings', '$totalMeetings', Icons.event, const Color(0xFF06B6D4)),
                  statCard('Rooms', '$totalRooms', Icons.meeting_room, const Color(0xFF10B981)),
                  statCard('Other Resources', '$totalOtherResources', Icons.devices, const Color(0xFFF59E0B)),
                  statCard('Busiest Resource', busiestResource, Icons.star, const Color(0xFF7C3AED)),
                  statCard('Bookings for Top Resource', '$busiestCount', Icons.bar_chart, const Color(0xFFEF4444)),
                  statCard('Total Scheduled Hours', totalScheduledHours.toStringAsFixed(1), Icons.access_time, const Color(0xFF0EA5E9)),
                ],
              ),
            ),
    );
  }
}
