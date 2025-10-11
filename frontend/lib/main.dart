import 'package:flutter/material.dart';
import 'services/sync_service.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/role_select_screen.dart';
import 'features/auth/driver_login_screen.dart';
import 'features/auth/passenger_login_screen.dart';
import 'features/auth/admin_login_screen.dart';
import 'features/auth/connector_login_screen.dart';
import 'features/auth/driver_register_screen.dart';
import 'features/auth/passenger_register_screen.dart';
import 'features/auth/admin_register_screen.dart';
import 'features/auth/connector_register_screen.dart';
import 'features/bus_timetable/bus_timetable_screen.dart';
import 'features/bus_timetable/customer_bus_timetable_screen.dart';
import 'features/dashboard/passenger_dashboard.dart';
import 'features/chatbot/chatbot_screen.dart';
import 'features/dashboard/connector_dashboard.dart';
import 'features/ride_share/create_ride_share_screen.dart';
import 'features/ride_share/connector_ride_requests_screen.dart';
import 'features/ride_share/passenger_ride_share_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background sync
  SyncService.instance.startAutoSync();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Rural Transportation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const RoleSelectScreen(),
        '/auth/driver/login': (context) => const DriverLoginScreen(),
        '/auth/driver/register': (context) => const DriverRegisterScreen(),
        '/driverHome': (context) => const _DriverHomePlaceholder(),
        '/auth/passenger/login': (context) => const PassengerLoginScreen(),
        '/auth/passenger/register': (context) => const PassengerRegisterScreen(),
        '/passengerHome': (context) => const PassengerDashboard(),
        '/auth/admin/login': (context) => const AdminLoginScreen(),
        '/auth/admin/register': (context) => const AdminRegisterScreen(),
        '/adminDashboard': (context) => const _AdminDashboardPlaceholder(),
        '/auth/connector/login': (context) => const ConnectorLoginScreen(),
        '/auth/connector/register': (context) => const ConnectorRegisterScreen(),
        '/connectorPanel': (context) => const ConnectorDashboard(),
        '/bus-timetable': (context) => const BusTimeTableScreen(),
        '/customer-bus-timetable': (context) => const CustomerBusTimeTableScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/ride-share/create': (context) => const CreateRideShareScreen(),
        '/ride-share/requests': (context) => const ConnectorRideRequestsScreen(),
        '/ride-share/passenger': (context) => const PassengerRideShareScreen(),
      },
    );
  }
}

// ... (rest of your placeholder classes remain the same)
class _DriverHomePlaceholder extends StatelessWidget {
  const _DriverHomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 64,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            const Text(
              'Driver Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/customer-bus-timetable'),
                    icon: const Icon(Icons.schedule),
                    label: const Text('View Bus Time Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerHomePlaceholder extends StatelessWidget {
  const _PassengerHomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Home'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 64, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            const Text(
              'Passenger Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/customer-bus-timetable'),
                icon: const Icon(Icons.schedule),
                label: const Text('View Bus Time Table'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardPlaceholder extends StatelessWidget {
  const _AdminDashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/bus-timetable'),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Manage Bus Time Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectorPanelPlaceholder extends StatelessWidget {
  const _ConnectorPanelPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connector Panel'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.connect_without_contact,
              size: 64,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connector Panel',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/customer-bus-timetable'),
                    icon: const Icon(Icons.schedule),
                    label: const Text('View Bus Time Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/chatbot'),
                    icon: const Icon(Icons.smart_toy),
                    label: const Text('AI Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}