import 'package:flutter/material.dart';
import 'package:frontend/services/ride_share_service.dart';

class CreateRideShareScreen extends StatefulWidget {
  const CreateRideShareScreen({super.key});

  @override
  CreateRideShareScreenState createState() => CreateRideShareScreenState();
}

class CreateRideShareScreenState extends State<CreateRideShareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedVehicleType = 'Car';
  int _seatCapacity = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _createRideShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await RideShareService().createRideShare({
        'from': _fromController.text,
        'to': _toController.text,
        'startTime': _timeController.text,
        'vehicleType': _selectedVehicleType,
        'seatCapacity': _seatCapacity,
        'price': double.parse(_priceController.text),
        'message': _messageController.text,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride share created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ride Share'),
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
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'From Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the starting location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the destination';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time (HH:MM)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the start time';
                  }
                  if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$')
                      .hasMatch(value!)) {
                    return 'Please enter a valid time in HH:MM format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Car', child: Text('Car')),
                  DropdownMenuItem(value: 'Motorbike', child: Text('Motorbike')),
                ],
                onChanged: (value) {
                  setState(() => _selectedVehicleType = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Seat Capacity: '),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_seatCapacity > 1) {
                        setState(() => _seatCapacity--);
                      }
                    },
                  ),
                  Text('$_seatCapacity'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => _seatCapacity++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (Rs.)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message for Passengers (Optional)',
                  hintText: 'e.g., I\'ll be waiting near the main gate, leaving 30 mins early, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                // No validator since it's optional
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createRideShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Ride Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}