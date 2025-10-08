import 'package:flutter/material.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  List<BusTimeTable> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDriverSchedules();
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        setState(() {
          _schedules = data.map((json) => BusTimeTable.fromJson(json)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schedules: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSchedule(BusTimeTable schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete the ${schedule.from} to ${schedule.to} route?',
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

    if (confirmed == true && schedule.id != null) {
      try {
        await ApiService.deleteDriverSchedule(schedule.id!);
        await _loadSchedules();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete schedule: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddEditForm([BusTimeTable? schedule]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverScheduleFormScreen(
          schedule: schedule,
          onSaved: () {
            _loadSchedules();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: const Text('My Schedules'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
              ),
            )
          : _schedules.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No schedules yet',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create your first schedule',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSchedules,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _schedules[index];
                      return _buildScheduleCard(schedule);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditForm(),
        backgroundColor: const Color(0xFFF97316),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Schedule',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(BusTimeTable schedule) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (schedule.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Approval';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBusTypeColor(schedule.busType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    schedule.busType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF1F2937),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddEditForm(schedule);
                    } else if (value == 'delete') {
                      _deleteSchedule(schedule);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (schedule.status == 'rejected' && schedule.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schedule.rejectionReason!,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        schedule.from,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Color(0xFFF97316), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('To', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        schedule.to,
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
                  child: _buildTimeInfo('Departure', schedule.startTime, Icons.schedule),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeInfo('Arrival', schedule.endTime, Icons.schedule),
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
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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

// Driver Schedule Form Screen
class DriverScheduleFormScreen extends StatefulWidget {
  final BusTimeTable? schedule;
  final VoidCallback onSaved;

  const DriverScheduleFormScreen({
    super.key,
    this.schedule,
    required this.onSaved,
  });

  @override
  State<DriverScheduleFormScreen> createState() => _DriverScheduleFormScreenState();
}

class _DriverScheduleFormScreenState extends State<DriverScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  String _selectedBusType = 'Normal';
  bool _isLoading = false;

  final List<String> _locations = [
    'Colombo', 'Kandy', 'Galle', 'Matara', 'Negombo', 'Anuradhapura',
    'Polonnaruwa', 'Ratnapura', 'Badulla', 'Trincomalee', 'Jaffna',
    'Kurunegala', 'Puttalam', 'Kalutara', 'Hambantota',
  ];

  final List<String> _busTypes = ['Normal', 'Express', 'Luxury', 'Semi-Luxury', 'Intercity'];

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.schedule?.from ?? '');
    _toController = TextEditingController(text: widget.schedule?.to ?? '');
    _startTimeController = TextEditingController(text: widget.schedule?.startTime ?? '');
    _endTimeController = TextEditingController(text: widget.schedule?.endTime ?? '');
    if (widget.schedule != null) {
      _selectedBusType = widget.schedule!.busType;
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (widget.schedule == null) {
        await ApiService.createDriverSchedule(
          from: _fromController.text,
          to: _toController.text,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          busType: _selectedBusType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule submitted for admin approval'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ApiService.updateDriverSchedule(
          id: widget.schedule!.id!,
          from: _fromController.text,
          to: _toController.text,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          busType: _selectedBusType,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated and submitted for approval'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Create Schedule' : 'Edit Schedule'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdown('From Location', _fromController, _locations),
              const SizedBox(height: 16),
              _buildDropdown('To Location', _toController, _locations),
              const SizedBox(height: 16),
              _buildTimeField('Start Time', _startTimeController),
              const SizedBox(height: 16),
              _buildTimeField('End Time', _endTimeController),
              const SizedBox(height: 16),
              _buildBusTypeDropdown(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.schedule == null ? 'Create Schedule' : 'Update Schedule',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, TextEditingController controller, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: const Color(0xFF374151),
          style: const TextStyle(color: Colors.white),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (value) => controller.text = value ?? '',
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.access_time, color: Colors.white),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.white),
          onTap: () => _selectTime(controller),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBusTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bus Type', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedBusType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: const Color(0xFF374151),
          style: const TextStyle(color: Colors.white),
          items: _busTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (value) => setState(() => _selectedBusType = value!),
        ),
      ],
    );
  }
}