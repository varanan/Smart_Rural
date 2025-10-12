import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService.getMyBookings();
      if (response['success']) {
        final List<dynamic> bookingData = response['data'];
        setState(() {
          _bookings = bookingData.map((json) => Booking.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load bookings';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading bookings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Booking> _getFilteredBookings() {
    if (_selectedFilter == 'all') return _bookings;
    
    return _bookings.where((booking) {
      switch (_selectedFilter) {
        case 'pending':
          return booking.bookingStatus == BookingStatus.pending;
        case 'confirmed':
          return booking.bookingStatus == BookingStatus.confirmed;
        case 'cancelled':
          return booking.bookingStatus == BookingStatus.cancelled;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final response = await ApiService.cancelBooking(bookingId);
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling booking: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel booking ${booking.bookingReference}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(booking.id!);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _viewBookingDetails(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _buildBookingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('all', 'All'),
            const SizedBox(width: 8),
            _buildFilterChip('pending', 'Pending'),
            const SizedBox(width: 8),
            _buildFilterChip('confirmed', 'Confirmed'),
            const SizedBox(width: 8),
            _buildFilterChip('cancelled', 'Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final filteredBookings = _getFilteredBookings();
    
    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'all' ? Icons.event_busy : Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' 
                  ? 'No bookings found'
                  : 'No ${_selectedFilter} bookings',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Book your first journey!'
                  : 'Try selecting a different filter',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBusTypeColor(booking.busTimeTable.busType),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.busTimeTable.busType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.bookingStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.bookingStatus.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${booking.busTimeTable.from} → ${booking.busTimeTable.to}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Departure',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${booking.busTimeTable.startTime} - ${_formatDate(booking.journeyDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Seats',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        booking.seatNumbers.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Ref',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        booking.bookingReference,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        'LKR ${booking.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (booking.bookingStatus == BookingStatus.pending ||
                  booking.bookingStatus == BookingStatus.confirmed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _viewBookingDetails(booking),
                        child: const Text('View Details'),
                      ),
                    ),
                    if (booking.bookingStatus == BookingStatus.pending) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showCancelDialog(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBusTypeColor(String busType) {
    switch (busType) {
      case 'Normal':
        return Colors.grey;
      case 'Express':
        return Colors.orange;
      case 'Luxury':
        return Colors.purple;
      case 'Semi-Luxury':
        return Colors.blue;
      case 'Intercity':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
