import 'package:flutter/material.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';
import '../../core/validators.dart';

class BusTimeTableForm extends StatefulWidget {
  final BusTimeTable? timetable;
  final VoidCallback onSaved;

  const BusTimeTableForm({super.key, this.timetable, required this.onSaved});

  @override
  State<BusTimeTableForm> createState() => _BusTimeTableFormState();
}

class _BusTimeTableFormState extends State<BusTimeTableForm> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  String _selectedBusType = 'Normal';
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
    if (widget.timetable != null) {
      _fromController.text = widget.timetable!.from;
      _toController.text = widget.timetable!.to;
      _startTimeController.text = widget.timetable!.startTime;
      _endTimeController.text = widget.timetable!.endTime;
      _selectedBusType = widget.timetable!.busType;
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

  Future<void> _saveTimetable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.timetable?.id != null) {
        // Update existing
        await ApiService.updateBusTimeTable(
          id: widget.timetable!.id!,
          from: _fromController.text.trim(),
          to: _toController.text.trim(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          busType: _selectedBusType,
        );
      } else {
        // Create new
        await ApiService.createBusTimeTable(
          from: _fromController.text.trim(),
          to: _toController.text.trim(),
          startTime: _startTimeController.text.trim(),
          endTime: _endTimeController.text.trim(),
          busType: _selectedBusType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.timetable?.id != null
                  ? 'Timetable updated successfully'
                  : 'Timetable created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save timetable: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                widget.timetable?.id != null
                    ? 'Edit Bus Schedule'
                    : 'Add Bus Schedule',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // From and To
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'From *',
                      _fromController,
                      _locations,
                      Icons.location_on,
                      true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'To *',
                      _toController,
                      _locations,
                      Icons.location_on,
                      true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start and End Time
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      'Start Time *',
                      _startTimeController,
                      _timeSlots,
                      Icons.schedule,
                      true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      'End Time *',
                      _endTimeController,
                      _timeSlots,
                      Icons.schedule,
                      true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bus Type
              _buildBusTypeField(),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTimetable,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.timetable?.id != null ? 'Update' : 'Save',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> options,
    IconData icon,
    bool required,
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
            hintText: 'Select ${label.replaceAll(' *', '')}',
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
          validator: required
              ? (value) => Validators.requiredField(
                  value,
                  fieldName: label.replaceAll(' *', ''),
                )
              : null,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            controller.text = value ?? '';
          },
        ),
      ],
    );
  }

  Widget _buildBusTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bus Type *',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedBusType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.directions_bus, color: Colors.grey),
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
          validator: (value) =>
              Validators.requiredField(value, fieldName: 'Bus type'),
          items: BusType.values
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type.displayName,
                  child: Text(
                    type.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedBusType = value!;
            });
          },
        ),
      ],
    );
  }
}
