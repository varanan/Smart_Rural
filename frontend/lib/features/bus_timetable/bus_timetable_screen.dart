import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';
import 'bus_timetable_form.dart';

class BusTimeTableScreen extends StatefulWidget {
  const BusTimeTableScreen({super.key});

  @override
  State<BusTimeTableScreen> createState() => _BusTimeTableScreenState();
}

class _BusTimeTableScreenState extends State<BusTimeTableScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _busTypeController = TextEditingController();

  List<BusTimeTable> _timetables = [];
  List<BusTimeTable> _filteredTimetables = [];
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _userRole;

  // Predefined locations (you can expand this list)
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
    '05:30',
    '06:00',
    '06:30',
    '07:00',
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00',
    '22:30',
    '23:00',
    '23:30',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadTimetables();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _busTypeController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    setState(() {
      _userRole = role;
      _isAdmin = role == 'admin' || role == 'super_admin';
    });
  }

  Future<void> _loadTimetables() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getBusTimeTable();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          _timetables = data
              .map((json) => BusTimeTable.fromJson(json))
              .toList();
          _filteredTimetables = _timetables;
        });
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
          endTime: _endTimeController.text.trim().isEmpty
              ? null
              : _endTimeController.text.trim(),
          busType: _busTypeController.text.trim().isEmpty
              ? null
              : _busTypeController.text.trim(),
        );

        if (response['success'] == true && response['data'] != null) {
          final List<dynamic> data = response['data'];
          setState(() {
            _filteredTimetables = data
                .map((json) => BusTimeTable.fromJson(json))
                .toList();
          });
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
    _endTimeController.clear();
    _busTypeController.clear();
    setState(() {
      _filteredTimetables = _timetables;
    });
  }

  // Admin-only functions
  Future<void> _deleteTimetable(BusTimeTable timetable) async {
    if (!_isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timetable'),
        content: Text(
          'Are you sure you want to delete the ${timetable.from} to ${timetable.to} route?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && timetable.id != null) {
      try {
        await ApiService.deleteBusTimeTable(timetable.id!);
        await _loadTimetables();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timetable deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete timetable: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddEditForm([BusTimeTable? timetable]) {
    if (!_isAdmin) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusTimeTableForm(
        timetable: timetable,
        onSaved: () {
          Navigator.pop(context);
          _loadTimetables();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with background image effect
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=60',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0x88000000),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Bus Time Table',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdmin
                          ? 'Manage bus schedules and routes'
                          : 'Search and view bus schedules',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Form
            Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Bus Time Table',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'From',
                          _fromController,
                          _locations,
                          Icons.location_on,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField(
                          'To',
                          _toController,
                          _locations,
                          Icons.location_on,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          'Start Time',
                          _startTimeController,
                          _timeSlots,
                          Icons.access_time,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField(
                          'End Time',
                          _endTimeController,
                          _timeSlots,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    'Bus Type',
                    _busTypeController,
                    BusType.values.map((e) => e.displayName).toList(),
                    Icons.directions_bus,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
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
                          label: Text(_isLoading ? 'Searching...' : 'Search'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: Container(
                color: const Color(0xFF1E293B),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFF97316),
                          ),
                        ),
                      )
                    : _filteredTimetables.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bus schedules found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search criteria',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTimetables.length,
                        itemBuilder: (context, index) {
                          final timetable = _filteredTimetables[index];
                          return _buildTimetableCard(timetable);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      // Only show FAB for admin users
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditForm(),
              backgroundColor: const Color(0xFFF97316),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Schedule',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildDropdownField(
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
            hintText: 'Select $label',
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          dropdownColor: const Color(0xFF374151),
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Any', style: TextStyle(color: Colors.grey)),
            ),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
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

  Widget _buildTimetableCard(BusTimeTable timetable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF374151),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      // Only show admin menu for admin users
                      if (_isAdmin) ...[
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          color: const Color(0xFF1F2937),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditForm(timetable);
                            } else if (value == 'delete') {
                              _deleteTimetable(timetable);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
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
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'To',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Departure',
                    timetable.startTime,
                    Icons.schedule,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInfo(
                    'Arrival',
                    timetable.endTime,
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF97316), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
