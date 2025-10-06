import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_auth_service.dart';
import '../../services/database_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait a bit for the splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check connectivity
    final connectivityService = ConnectivityService();
    final isOnline = await connectivityService.isConnected();
    
    // Check if user was in offline mode
    final wasOffline = await OfflineAuthService.isOfflineMode();
    
    // Check if there's cached data
    final cachedCount = await DatabaseService.instance.getCachedTimetablesCount();
    
    if (!mounted) return;

    // If user was offline and has cached data, go directly to bus timetable
    if (wasOffline && cachedCount > 0) {
      Navigator.pushReplacementNamed(context, '/customer-bus-timetable');
      return;
    }

    // If offline and no cached data, show message and go to role selection
    if (!isOnline && cachedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please connect to internet to download bus schedules.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    // Go to role selection
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Rural Transportation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}