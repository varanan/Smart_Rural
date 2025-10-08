import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
import 'features/reviews/my_reviews_screen.dart';
import 'features/reviews/all_reviews_screen.dart';
import 'features/reviews/review_form_screen.dart';
import 'models/bus_timetable.dart';
import 'features/reviews/bus_reviews_screen.dart';
import 'features/admin/verify_users_screen.dart';
// Add these imports after line 23
import 'features/driver/driver_schedule_screen.dart';
import 'features/driver/notifications_screen.dart';
import 'features/admin/admin_schedule_approval_screen.dart';

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
        '/auth/passenger/register': (context) =>
            const PassengerRegisterScreen(),
        '/passengerHome': (context) => const PassengerDashboard(),
        '/auth/admin/login': (context) => const AdminLoginScreen(),
        '/auth/admin/register': (context) => const AdminRegisterScreen(),
        '/adminDashboard': (context) => const _AdminDashboardPlaceholder(),
        '/auth/connector/login': (context) => const ConnectorLoginScreen(),
        '/auth/connector/register': (context) =>
            const ConnectorRegisterScreen(),
        '/connectorPanel': (context) => const _ConnectorPanelPlaceholder(),
        '/bus-timetable': (context) => const BusTimeTableScreen(), // Admin view
        '/customer-bus-timetable': (context) =>
            const CustomerBusTimeTableScreen(), // Customer view
        '/chatbot': (context) => const ChatbotScreen(), // AI Chatbot
        '/my-reviews': (context) => const MyReviewsScreen(),
        '/all-reviews': (context) => const AllReviewsScreen(),
        '/admin-reviews': (context) => const AllReviewsScreen(isAdmin: true),
        '/write-review': (context) {
          final bus = ModalRoute.of(context)?.settings.arguments as BusTimeTable?;
          if (bus == null) {
            return const Scaffold(
              body: Center(child: Text('Error: No bus data')),
            );
          }
          return ReviewFormScreen(bus: bus);
        },
        '/bus-reviews': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return BusReviewsScreen(
            busId: args?['busId'] ?? '',
            busInfo: args?['busInfo'],
          );
        },
        '/driver-schedules': (context) => const DriverScheduleScreen(),
        '/driver-notifications': (context) => const NotificationsScreen(),
        '/admin-schedule-approval': (context) => const AdminScheduleApprovalScreen(),
      },
    );
  }
}

class _DriverHomePlaceholder extends StatefulWidget {
  const _DriverHomePlaceholder();

  @override
  State<_DriverHomePlaceholder> createState() => _DriverHomePlaceholderState();
}

class _DriverHomePlaceholderState extends State<_DriverHomePlaceholder> {
  bool _isVerified = false;
  bool _isLoading = true;
  String _userName = '';
  String _verificationStatus = 'pending';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _isVerified = userData['isVerified'] ?? false;
          _userName = userData['fullName'] ?? 'Driver';
          _verificationStatus = userData['verificationStatus'] ?? 'pending';
          _rejectionReason = userData['rejectionReason'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.directions_bus,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, $_userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Verification Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _verificationStatus == 'rejected'
                            ? Colors.red.withOpacity(0.2)
                            : (_isVerified
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _verificationStatus == 'rejected'
                              ? Colors.red
                              : (_isVerified ? Colors.green : Colors.orange),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _verificationStatus == 'rejected'
                                ? Icons.cancel
                                : (_isVerified
                                    ? Icons.verified
                                    : Icons.pending),
                            color: _verificationStatus == 'rejected'
                                ? Colors.red
                                : (_isVerified ? Colors.green : Colors.orange),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _verificationStatus == 'rejected'
                                ? 'Profile Rejected'
                                : (_isVerified
                                    ? 'Profile Verified'
                                    : 'Verification Pending'),
                            style: TextStyle(
                              color: _verificationStatus == 'rejected'
                                  ? Colors.red
                                  : (_isVerified ? Colors.green : Colors.orange),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isVerified) ...[
                      const SizedBox(height: 12),
                      Text(
                        _verificationStatus == 'rejected'
                            ? 'Your profile was rejected by admin'
                            : 'Your profile is awaiting admin verification',
                        style: TextStyle(
                          color: _verificationStatus == 'rejected' ? Colors.red : Colors.grey,
                          fontSize: 14,
                          fontWeight: _verificationStatus == 'rejected' 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_verificationStatus == 'rejected' && _rejectionReason != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Rejection Reason:',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _rejectionReason!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/driver-schedules',
                            ),
                            icon: const Icon(Icons.schedule),
                            label: const Text('My Schedules'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/driver-notifications',
                            ),
                            icon: const Icon(Icons.notifications),
                            label: const Text('Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/customer-bus-timetable',
                            ),
                            icon: const Icon(Icons.schedule),
                            label: const Text('View Bus Time Table'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/chatbot',
                            ),
                            icon: const Icon(Icons.smart_toy),
                            label: const Text('AI Assistant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/all-reviews',
                            ),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('View Reviews'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show Re-Register section only for rejected drivers
                    if (_verificationStatus == 'rejected') ...[
                      const Divider(thickness: 2, color: Colors.grey),
                      const SizedBox(height: 24),
                      
                      // Warning message
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Account Rejected',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You can re-register with corrected information using the same email address.',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Re-Register Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Show confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Re-Register Account'),
                                content: const Text(
                                  'This will log you out and allow you to register again with corrected information.\n\n'
                                  'You can use the same email address.\n\n'
                                  'Are you sure you want to continue?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Yes, Re-Register'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              // Clear all stored data
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();
                              
                              if (mounted) {
                                // Navigate to registration screen
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/auth/driver/register',
                                  (route) => false,
                                );
                                
                                // Show helpful message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You can now register again with corrected information',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 28),
                          label: const Text(
                            'Re-Register with New Info',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerifyUsersScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verify Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminScheduleApprovalScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.pending_actions),
                    label: const Text('Approve Schedules'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin-reviews'),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('View Reviews'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
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

class _ConnectorPanelPlaceholder extends StatefulWidget {
  const _ConnectorPanelPlaceholder();

  @override
  State<_ConnectorPanelPlaceholder> createState() =>
      _ConnectorPanelPlaceholderState();
}

class _ConnectorPanelPlaceholderState
    extends State<_ConnectorPanelPlaceholder> {
  bool _isVerified = false;
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _isVerified = userData['isVerified'] ?? false;
          _userName = userData['fullName'] ?? 'Connector';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connector Panel'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.connect_without_contact,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, $_userName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Verification Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isVerified
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isVerified ? Colors.green : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isVerified ? Icons.verified : Icons.pending,
                            color: _isVerified ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isVerified
                                ? 'Profile Verified'
                                : 'Verification Pending',
                            style: TextStyle(
                              color: _isVerified ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isVerified) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Your profile is awaiting admin verification',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/customer-bus-timetable',
                            ),
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
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/chatbot',
                            ),
                            icon: const Icon(Icons.smart_toy),
                            label: const Text('AI Assistant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/all-reviews',
                            ),
                            icon: const Icon(Icons.rate_review),
                            label: const Text('View Reviews'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
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
            ),
    );
  }
}