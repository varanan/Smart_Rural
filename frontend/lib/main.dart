import 'package:flutter/material.dart';
import 'features/auth/role_select_screen.dart';
import 'features/auth/driver_login_screen.dart';
import 'features/auth/passenger_login_screen.dart';
import 'features/auth/admin_login_screen.dart';
import 'features/auth/connector_login_screen.dart';
import 'features/auth/driver_register_screen.dart';
import 'features/auth/passenger_register_screen.dart';
import 'features/auth/admin_register_screen.dart';
import 'features/auth/connector_register_screen.dart';
import '../../core/validators.dart';
import '../../widgets/gradient_button.dart';

void main() {
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
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectScreen(),
        '/auth/driver/login': (context) => const DriverLoginScreen(),
        '/auth/driver/register': (context) => const DriverRegisterScreen(),
        '/driverHome': (context) => const _DriverHomePlaceholder(),
        '/auth/passenger/login': (context) => const PassengerLoginScreen(),
        '/auth/passenger/register': (context) => const PassengerRegisterScreen(),
        '/passengerHome': (context) => const _PassengerHomePlaceholder(),
        '/auth/admin/login': (context) => const AdminLoginScreen(),
        '/auth/admin/register': (context) => const AdminRegisterScreen(),
        '/adminDashboard': (context) => const _AdminDashboardPlaceholder(),
        '/auth/connector/login': (context) => const ConnectorLoginScreen(),
        '/auth/connector/register': (context) => const ConnectorRegisterScreen(),
        '/connectorPanel': (context) => const _ConnectorPanelPlaceholder(),
      },
    );
  }
}

class _DriverHomePlaceholder extends StatelessWidget {
  const _DriverHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Home')),
      body: const Center(child: Text('Driver Home')),
    );
  }
}

class _PassengerHomePlaceholder extends StatelessWidget {
  const _PassengerHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Passenger Home')),
      body: const Center(child: Text('Passenger Home')),
    );
  }
}

class _AdminDashboardPlaceholder extends StatelessWidget {
  const _AdminDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(child: Text('Admin Dashboard')),
    );
  }
}

class _ConnectorPanelPlaceholder extends StatelessWidget {
  const _ConnectorPanelPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connector Panel')),
      body: const Center(child: Text('Connector Panel')),
    );
  }
}