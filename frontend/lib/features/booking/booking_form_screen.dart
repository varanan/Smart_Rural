import 'package:flutter/material.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';
import 'my_bookings_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final BusTimeTable busTimeTable;
  final DateTime travelDate;
  final int seatNumber;
  final double fare;

  const BookingFormScreen({
    Key? key,
    required this.busTimeTable,
    required this.travelDate,
    required this.seatNumber,
    required this.fare,
  }) : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.createBooking(
        busId: widget.busTimeTable.id!,
        passengerName: _nameController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        seatNumber: widget.seatNumber,
        travelDate: widget.travelDate,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to my bookings screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
            (route) => route.isFirst,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create booking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(
                        'Route',
                        '${widget.busTimeTable.from} → ${widget.busTimeTable.to}',
                      ),
                      _buildSummaryRow(
                        'Date',
                        widget.travelDate.toString().split(' ')[0],
                      ),
                      _buildSummaryRow(
                        'Time',
                        '${widget.busTimeTable.startTime} - ${widget.busTimeTable.endTime}',
                      ),
                      _buildSummaryRow('Bus Type', widget.busTimeTable.busType),
                      _buildSummaryRow(
                        'Seat Number',
                        widget.seatNumber.toString(),
                      ),
                      _buildSummaryRow(
                        'Fare',
                        'Rs. ${widget.fare.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Passenger details form
              const Text(
                'Passenger Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '0771234567',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^0\d{9}$').hasMatch(value.trim())) {
                    return 'Please enter a valid Sri Lankan phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Confirm booking button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
