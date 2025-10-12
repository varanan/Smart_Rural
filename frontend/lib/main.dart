import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/api_service.dart';
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
import 'features/booking/seat_selection_screen.dart';
import 'features/booking/passenger_details_screen.dart';
import 'features/booking/payment_screen.dart';
import 'features/booking/booking_confirmation_screen.dart';
import 'features/booking/my_bookings_screen.dart';
import 'features/booking/booking_details_screen.dart';
import 'core/auth_api.dart';
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
        '/bus-timetable': (context) => const BusTimeTableScreen(), // Admin view
        '/customer-bus-timetable': (context) => const CustomerBusTimeTableScreen(), // Customer view
        // Booking routes
        '/seat-selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SeatSelectionScreen(
            timetable: args['timetable'],
            journeyDate: args['journeyDate'],
          );
        },
        '/passenger-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PassengerDetailsScreen(
            timetable: args['timetable'],
            journeyDate: args['journeyDate'],
            selectedSeats: args['selectedSeats'],
            pricePerSeat: args['pricePerSeat'] ?? 100.0,
          );
        },
        '/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PaymentScreen(
            timetable: args['timetable'],
            journeyDate: args['journeyDate'],
            selectedSeats: args['selectedSeats'],
            passengerDetails: args['passengerDetails'],
            pricePerSeat: args['pricePerSeat'] ?? 100.0,
          );
        },
        '/booking-confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingConfirmationScreen(
            timetable: args['timetable'],
            journeyDate: args['journeyDate'],
            selectedSeats: args['selectedSeats'],
            passengerDetails: args['passengerDetails'],
            transactionId: args['transactionId'],
            totalAmount: args['totalAmount'],
          );
        },
        '/my-bookings': (context) => const MyBookingsScreen(),
        '/booking-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingDetailsScreen(booking: args['booking']);
        },
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
        '/ride-share/create': (context) => const CreateRideShareScreen(),
        '/ride-share/requests': (context) => const ConnectorRideRequestsScreen(),
        '/ride-share/passenger': (context) => const PassengerRideShareScreen(),
      },
    );
  }
}

class _DriverHomePlaceholder extends StatefulWidget {
  const _DriverHomePlaceholder();

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear all stored authentication data
      await AuthStorage.clear();
      
      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to role selection screen
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/', 
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiService.logout();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/', 
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
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
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear all stored authentication data
      await AuthStorage.clear();
      
      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to role selection screen
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/', 
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Home'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
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
                    onPressed: () =>
                        Navigator.pushNamed(context, '/my-bookings'),
                    icon: const Icon(Icons.book_online),
                    label: const Text('My Bookings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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

class _AdminDashboardPlaceholder extends StatelessWidget {
  const _AdminDashboardPlaceholder();

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear all stored authentication data
      await AuthStorage.clear();
      
      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to role selection screen
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/', 
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
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
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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