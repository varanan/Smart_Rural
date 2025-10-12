import 'package:flutter/material.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BusTimeTable timetable;
  final String journeyDate;
  final List<String> selectedSeats;
  final Map<String, String> passengerDetails;
  final String transactionId;
  final double totalAmount;

  const BookingConfirmationScreen({
    Key? key,
    required this.timetable,
    required this.journeyDate,
    required this.selectedSeats,
    required this.passengerDetails,
    required this.transactionId,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isProcessingBooking = false;
  bool _bookingCompleted = false;
  String? _bookingReference;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processBooking();
  }

  Future<void> _processBooking() async {
    try {
      setState(() {
        _isProcessingBooking = true;
        _error = null;
      });

      // Create the booking
      final bookingResponse = await ApiService.createBooking(
        timetableId: widget.timetable.id!,
        seatNumbers: widget.selectedSeats,
        journeyDate: widget.journeyDate,
        totalAmount: widget.totalAmount,
      );

      if (bookingResponse['success']) {
        final bookingId = bookingResponse['data']['_id'];

        // Process the payment
        final paymentResponse = await ApiService.processPayment(
          bookingId: bookingId,
          paymentMethod: 'card', // Default for mock payments
          cardNumber: '4242424242424242', // Default success card
        );

        if (paymentResponse['success']) {
          setState(() {
            _bookingCompleted = true;
            _bookingReference = bookingResponse['data']['bookingReference'];
            _isProcessingBooking = false;
          });
        } else {
          throw Exception(paymentResponse['message'] ?? 'Payment processing failed');
        }
      } else {
        throw Exception(bookingResponse['message'] ?? 'Booking creation failed');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessingBooking = false;
      });
    }
  }

  void _goToMyBookings() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/my-bookings',
      (route) => false,
    );
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  void _retryBooking() {
    _processBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isProcessingBooking
          ? _buildProcessingState()
          : _error != null
              ? _buildErrorState()
              : _buildSuccessState(),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
          ),
          const SizedBox(height: 24),
          const Text(
            'Processing your booking...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we confirm your booking and process payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Booking Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retryBooking,
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSuccessHeader(),
          const SizedBox(height: 24),
          _buildBookingDetails(),
          const SizedBox(height: 24),
          _buildPaymentDetails(),
          const SizedBox(height: 32),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking reference is: $_bookingReference',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A confirmation email has been sent to your email address.',
                      style: TextStyle(fontSize: 12),
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

  Widget _buildBookingDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Passenger', widget.passengerDetails['name']!),
            _buildDetailRow('Email', widget.passengerDetails['email']!),
            _buildDetailRow('Phone', widget.passengerDetails['phone']!),
            const Divider(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBusTypeColor(widget.timetable.busType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.timetable.busType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.timetable.from} → ${widget.timetable.to}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Seats', widget.selectedSeats.join(', ')),
            _buildDetailRow('Departure', '${widget.timetable.startTime} - ${_formatDate(widget.journeyDate)}'),
            _buildDetailRow('Arrival', widget.timetable.endTime),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transaction ID', widget.transactionId),
            _buildDetailRow('Payment Method', 'Credit Card (Mock)'),
            _buildDetailRow('Amount Paid', 'LKR ${widget.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Status', 'Completed', statusColor: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToMyBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'View My Bookings',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goToHome,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Book Another Journey',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: statusColor ?? Colors.black,
              ),
            ),
          ),
        ],
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
