import 'package:flutter/material.dart';
import 'package:frontend/models/ride_share.dart';
import 'package:frontend/services/ride_share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerRideShareScreen extends StatefulWidget {
  const PassengerRideShareScreen({super.key});

  @override
  PassengerRideShareScreenState createState() => PassengerRideShareScreenState();
}

class PassengerRideShareScreenState extends State<PassengerRideShareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RideShareService _service = RideShareService();
  List<RideShare> _availableRides = [];
  List<RideShare> _myRides = [];
  bool _isLoading = true;
  String? _error;
  String? _passengerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPassengerId().then((_) => _loadRides());
  }

  Future<void> _loadPassengerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _passengerId = prefs.getString('userId');
    });
  }

  Future<void> _loadRides() async {
    try {
      setState(() => _isLoading = true);
      final availableRides = await _service.getAllRideShares();
      List<RideShare> myRides = [];
      
      if (_passengerId != null) {
        myRides = await _service.getPassengerRides(_passengerId!);
      }

      setState(() {
        _availableRides = availableRides;
        _myRides = myRides;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestRide(RideShare ride) async {
    if (_passengerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a ride')),
      );
      return;
    }

    try {
      await _service.requestRide(ride.id, _passengerId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride requested successfully')),
      );
      _loadRides(); // Reload to update the lists
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Sharing'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Rides'),
            Tab(text: 'My Rides'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _AvailableRidesTab(
                      rides: _availableRides,
                      onRequestRide: _requestRide,
                    ),
                    _MyRidesTab(rides: _myRides),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _AvailableRidesTab extends StatelessWidget {
  final List<RideShare> rides;
  final Function(RideShare) onRequestRide;

  const _AvailableRidesTab({
    required this.rides,
    required this.onRequestRide,
  });

  @override
  Widget build(BuildContext context) {
    return rides.isEmpty
        ? const Center(child: Text('No available rides'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${ride.from} → ${ride.to}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Time: ${ride.startTime}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle: ${ride.vehicleType}'),
                          Text(
                            'Available Seats: ${ride.availableSeats}',
                          ),
                          Text('Price: Rs. ${ride.price}'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: ride.availableSeats > 0
                                  ? () => onRequestRide(ride)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                ride.availableSeats > 0
                                    ? 'Request Ride'
                                    : 'No Seats Available',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

class _MyRidesTab extends StatelessWidget {
  final List<RideShare> rides;

  const _MyRidesTab({required this.rides});

  @override
  Widget build(BuildContext context) {
    return rides.isEmpty
        ? const Center(child: Text('No ride requests'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final myRequest = ride.requests.firstWhere(
                (req) => true, // You would check for the current passenger's ID
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        '${ride.from} → ${ride.to}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Time: ${ride.startTime}'),
                      trailing: _getStatusChip(myRequest.status),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle: ${ride.vehicleType}'),
                          Text('Price: Rs. ${ride.price}'),
                          Text(
                            'Requested on: ${_formatDate(myRequest.requestedAt)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _getStatusChip(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute}';
  }
}