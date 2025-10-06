import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../services/offline_auth_service.dart';
import 'dart:convert';
import '../reviews/bus_reviews_screen.dart';

class CustomerBusTimeTableScreen extends StatefulWidget {
  const CustomerBusTimeTableScreen({super.key});

  @override
  State<CustomerBusTimeTableScreen> createState() =>
      _CustomerBusTimeTableScreenState();
}

class _CustomerBusTimeTableScreenState
    extends State<CustomerBusTimeTableScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _busTypeController = TextEditingController();

  List<BusTimeTable> _filteredTimetables = [];
  bool _isLoading = false;

  // Predefined locations
  final List<String> _locations = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Negombo',
    'Anuradhapura',
    'Polonnaruwa',
    'Ratnapura',
    'Badulla',
    'Trincomalee',
    'Jaffna',
    'Kurunegala',
    'Puttalam',
    'Kalutara',
    'Hambantota',
  ];

  // Time slots
  final List<String> _timeSlots = [
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadTimetables();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _startTimeController.dispose();
    _busTypeController.dispose();
    super.dispose();
  }

  // ===========================
  // LOAD TIMETABLES (with offline indicator)
  // ===========================
  Future<void> _loadTimetables() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getBusTimeTable();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          _filteredTimetables =
              data.map((json) => BusTimeTable.fromJson(json)).toList();
        });

        // ✅ Show offline indicator if data is from local DB
        if (response['offline'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Showing offline data'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load timetables: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===========================
  // SEARCH
  // ===========================
  void _searchTimetables() {
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final response = await ApiService.getBusTimeTable(
          from: _fromController.text.trim().isEmpty
              ? null
              : _fromController.text.trim(),
          to: _toController.text.trim().isEmpty
              ? null
              : _toController.text.trim(),
          startTime: _startTimeController.text.trim().isEmpty
              ? null
              : _startTimeController.text.trim(),
          busType: _busTypeController.text.trim().isEmpty
              ? null
              : _busTypeController.text.trim(),
        );

        if (response['success'] == true && response['data'] != null) {
          final List<dynamic> data = response['data'];
          setState(() {
            _filteredTimetables =
                data.map((json) => BusTimeTable.fromJson(json)).toList();
          });

          // ✅ Offline status during search
          if (response['offline'] == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Showing offline data'),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Search failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  void _clearFilters() {
    _fromController.clear();
    _toController.clear();
    _startTimeController.clear();
    _busTypeController.clear();
    _loadTimetables();
  }

  // ===========================
  // NEW: Show offline status dialog
  // ===========================
  Future<void> _showOfflineStatus() async {
    final isOnline = await ConnectivityService().isConnected();
    final cachedCount = await DatabaseService.instance.getCachedTimetablesCount();
    final lastSync = await SyncService.instance.getLastSyncTime();
    
    String lastSyncText = 'Never';
    if (lastSync != null) {
      final difference = DateTime.now().difference(lastSync);
      if (difference.inMinutes < 1) {
        lastSyncText = 'Just now';
      } else if (difference.inHours < 1) {
        lastSyncText = '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        lastSyncText = '${difference.inHours} hours ago';
      } else {
        lastSyncText = '${difference.inDays} days ago';
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              const Text('Offline Status'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow(
                'Connection Status',
                isOnline ? 'Online' : 'Offline',
                isOnline ? Colors.green : Colors.orange,
              ),
              const Divider(),
              _buildStatusRow(
                'Cached Schedules',
                '$cachedCount routes',
                Colors.blue,
              ),
              const Divider(),
              _buildStatusRow(
                'Last Sync',
                lastSyncText,
                Colors.grey,
              ),
            ],
          ),
          actions: [
            if (isOnline)
              TextButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await SyncService.instance.syncData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Data synced successfully!'
                              : 'Sync failed. Please try again.',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    _loadTimetables(); // Reload data
                  }
                },
              ),
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Get More Features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Login to access personalized features, save favorite routes, and get real-time updates',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Continue as Guest'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/auth/passenger/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Login'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: const Text('Bus Schedules'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ Info button to show offline status
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showOfflineStatus,
            tooltip: 'Offline Status',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLoginPrompt,
        icon: Icon(Icons.person),
        label: Text('Login'),
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Search Section
          Container(
            color: const Color(0xFF0F172A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Bus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // From & To Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleDropdown(
                        'From',
                        _fromController,
                        _locations,
                        Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimpleDropdown(
                        'To',
                        _toController,
                        _locations,
                        Icons.location_on,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time & Type Dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleDropdown(
                        'Departure Time',
                        _startTimeController,
                        _timeSlots,
                        Icons.access_time,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimpleDropdown(
                        'Bus Type',
                        _busTypeController,
                        BusType.values.map((e) => e.displayName).toList(),
                        Icons.directions_bus,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchTimetables,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _isLoading ? 'Searching...' : 'Search Buses',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🚌 Results Section
          Expanded(
            child: Container(
              color: const Color(0xFF1E293B),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching for buses...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : _filteredTimetables.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_outlined,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No buses found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try different search criteria',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTimetables.length,
                          itemBuilder: (context, index) {
                            final timetable = _filteredTimetables[index];
                            return _buildSimpleTimetableCard(timetable);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDropdown(
    String label,
    TextEditingController controller,
    List<String> options,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            hintText: 'Any',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          dropdownColor: const Color(0xFF374151),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Any', style: TextStyle(color: Colors.grey)),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
          onChanged: (value) {
            controller.text = value ?? '';
          },
        ),
      ],
    );
  }

  Widget _buildSimpleTimetableCard(BusTimeTable timetable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF374151),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bus Type
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBusTypeColor(timetable.busType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    timetable.busType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route Info
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FROM',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        timetable.from,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Icon(Icons.arrow_forward,
                      color: Color(0xFFF97316), size: 24),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TO',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        timetable.to,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Time Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeDisplay('Departure', timetable.startTime),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  _buildTimeDisplay('Arrival', timetable.endTime),
                ],
              ),
            ),
            
            // ✅ NEW: Add Review Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Check if user is logged in
                  
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('access_token');
                  if (token == null) {
                    // Show login prompt
                    _showLoginPrompt();
                    return;
                  }
                  
                  // Navigate to review form
                  if (mounted) {
                    Navigator.pushNamed(
                      context,
                      '/write-review',
                      arguments: timetable,
                    );
                  }
                },
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Write Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316),
                  side: const BorderSide(color: Color(0xFFF97316)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusReviewsScreen(
                        busId: timetable.id ?? '',
                        busInfo: timetable,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('View All Reviews'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF60A5FA),
                  side: const BorderSide(color: Color(0xFF60A5FA)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(String label, String time) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFFF97316),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBusTypeColor(String busType) {
    switch (busType.toLowerCase()) {
      case 'express':
        return Colors.red;
      case 'luxury':
        return Colors.purple;
      case 'semi-luxury':
        return Colors.blue;
      case 'intercity':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}