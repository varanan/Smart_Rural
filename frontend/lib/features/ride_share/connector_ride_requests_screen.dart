import 'package:flutter/material.dart';
import 'package:frontend/models/ride_share.dart';
import 'package:frontend/services/ride_share_service.dart';
import 'package:frontend/features/ride_share/create_ride_share_screen.dart';

class ConnectorRideRequestsScreen extends StatefulWidget {
  const ConnectorRideRequestsScreen({super.key});

  @override
  ConnectorRideRequestsScreenState createState() =>
      ConnectorRideRequestsScreenState();
}

class ConnectorRideRequestsScreenState extends State<ConnectorRideRequestsScreen> {
  final RideShareService _service = RideShareService();
  List<RideShare> _rides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      setState(() => _isLoading = true);
      final rides = await _service.getConnectorRides();
      setState(() {
        _rides = rides;
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

  Future<void> _handleRequestResponse(
    RideShare ride,
    RideRequest request,
    String status,
  ) async {
    try {
      await _service.respondToRequest(ride.id, request.id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status successfully')),
      );
      _loadRides(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleRideStatus(RideShare ride) async {
    try {
      await _service.updateRideStatus(ride.id, !ride.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ride ${!ride.isActive ? 'activated' : 'deactivated'} successfully',
          ),
        ),
      );
      _loadRides(); // Reload the list
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
        title: const Text('Your Ride Shares'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRides,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _rides.isEmpty
                    ? const Center(
                        child: Text('No ride shares found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rides.length,
                        itemBuilder: (context, index) {
                          final ride = _rides[index];
                          return _RideShareCard(
                            ride: ride,
                            onStatusToggle: () => _toggleRideStatus(ride),
                            onAcceptRequest: (request) =>
                                _handleRequestResponse(ride, request, 'accepted'),
                            onRejectRequest: (request) =>
                                _handleRequestResponse(ride, request, 'rejected'),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRideShareScreen(),
            ),
          );
          _loadRides(); // Reload after returning
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create New'),
      ),
    );
  }
}

class _RideShareCard extends StatelessWidget {
  final RideShare ride;
  final VoidCallback onStatusToggle;
  final Function(RideRequest) onAcceptRequest;
  final Function(RideRequest) onRejectRequest;

  const _RideShareCard({
    required this.ride,
    required this.onStatusToggle,
    required this.onAcceptRequest,
    required this.onRejectRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              '${ride.from} → ${ride.to}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Time: ${ride.startTime}'),
            trailing: Switch(
              value: ride.isActive,
              onChanged: (_) => onStatusToggle(),
              activeColor: const Color(0xFF2563EB),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle: ${ride.vehicleType}'),
                Text(
                  'Seats: ${ride.availableSeats}/${ride.seatCapacity}',
                ),
                Text('Price: Rs. ${ride.price}'),
              ],
            ),
          ),
          if (ride.requests.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requests',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...ride.requests.map((request) => _RequestItem(
                        request: request,
                        onAccept: () => onAcceptRequest(request),
                        onReject: () => onRejectRequest(request),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final RideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestItem({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Passenger Name
                Text(
                  request.passengerDetails?['fullName'] ?? 'Passenger',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // Passenger Phone
                if (request.passengerDetails?['phone'] != null)
                  Text(
                    'Phone: ${request.passengerDetails!['phone']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                // Passenger Email (if available)
                if (request.passengerDetails?['email'] != null)
                  Text(
                    'Email: ${request.passengerDetails!['email']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 4),
                // Request Status
                Text(
                  'Status: ${request.status}',
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (request.status == 'pending') ...[
            TextButton(
              onPressed: onAccept,
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onReject,
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}