import 'package:flutter/material.dart';
import 'package:frontend/features/ride_share/create_ride_share_screen.dart';
import 'package:frontend/features/ride_share/connector_ride_requests_screen.dart';
import 'package:frontend/features/chatbot/chatbot_screen.dart';
import 'package:frontend/features/bus_timetable/customer_bus_timetable_screen.dart';

class ConnectorDashboard extends StatelessWidget {
  const ConnectorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connector Dashboard'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _QuickActionCard(
                  title: 'Create Ride Share',
                  icon: Icons.add_circle_outline,
                  color: const Color(0xFF2563EB),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRideShareScreen(),
                    ),
                  ),
                ),
                _QuickActionCard(
                  title: 'View Ride Requests',
                  icon: Icons.list_alt,
                  color: const Color(0xFFF97316),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConnectorRideRequestsScreen(),
                    ),
                  ),
                ),
                _QuickActionCard(
                  title: 'Bus Timetable',
                  icon: Icons.schedule,
                  color: const Color(0xFF059669),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/customer-bus-timetable',
                  ),
                ),
                _QuickActionCard(
                  title: 'AI Assistant',
                  icon: Icons.smart_toy,
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pushNamed(context, '/chatbot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}