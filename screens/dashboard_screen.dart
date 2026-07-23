import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';
import 'resources_screen.dart';
import 'meetings_screen.dart';
import 'optimize_meeting_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    final authService = AuthService();
    await authService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget dashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scheduler'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage meetings, resources and schedule rooms from one place.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          dashboardCard(
            context: context,
            title: 'Manage Resources',
            subtitle: 'Create, edit and organize rooms, equipment and people',
            icon: Icons.meeting_room,
            colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            screen: const ResourcesScreen(),
          ),
          dashboardCard(
            context: context,
            title: 'View Meetings',
            subtitle: 'Track upcoming meetings and manage schedules',
            icon: Icons.calendar_month,
            colors: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
            screen: const MeetingsScreen(),
          ),
          dashboardCard(
            context: context,
            title: 'Smart Schedule',
            subtitle: 'Automatically assign the best available resource',
            icon: Icons.auto_awesome,
            colors: const [Color(0xFF10B981), Color(0xFF059669)],
            screen: const OptimizeMeetingScreen(),
          ),
          dashboardCard(
            context: context,
            title: 'Analytics',
            subtitle: 'See resource usage and scheduling insights',
            icon: Icons.analytics,
            colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
            screen: const AnalyticsScreen(),
          ),
        ],
      ),
    );
  }
}
