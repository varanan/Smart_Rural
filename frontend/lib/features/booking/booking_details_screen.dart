import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailsScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Payment? _payment;
  bool _isLoadingPayment = false;
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    if (widget.booking.payment != null) {
      _payment = widget.booking.payment;
    } else {
      _loadPaymentDetails();
    }
  }

  Future<void> _loadPaymentDetails() async {
    try {
      setState(() {
        _isLoadingPayment = true;
        _paymentError = null;
      });

      final response = await ApiService.getPaymentByBookingId(widget.booking.id!);
      if (response['success']) {
        setState(() {
          _payment = Payment.fromJson(response['data']);
          _isLoadingPayment = false;
        });
      } else {
        setState(() {
          _paymentError = response['message'] ?? 'Failed to load payment details';
          _isLoadingPayment = false;
        });
      }
    } catch (e) {
      setState(() {
        _paymentError = 'Error loading payment details: ${e.toString()}';
        _isLoadingPayment = false;
      });
    }
  }

  Future<void> _cancelBooking() async {
    try {
      final response = await ApiService.cancelBooking(widget.booking.id!);
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate booking was cancelled
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

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel booking ${widget.booking.bookingReference}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          if (widget.booking.bookingStatus == BookingStatus.pending ||
              widget.booking.bookingStatus == BookingStatus.confirmed)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _showCancelDialog,
              tooltip: 'Cancel Booking',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingHeader(),
            const SizedBox(height: 16),
            _buildBookingInfo(),
            const SizedBox(height: 16),
            _buildJourneyDetails(),
            const SizedBox(height: 16),
            _buildPassengerDetails(),
            const SizedBox(height: 16),
            _buildPaymentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingHeader() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(widget.booking.bookingStatus),
              size: 48,
              color: _getStatusColor(widget.booking.bookingStatus),
            ),
            const SizedBox(height: 12),
            Text(
              'Booking ${widget.booking.bookingStatus.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(widget.booking.bookingStatus),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.booking.bookingReference,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Booking ID', widget.booking.id!),
            _buildInfoRow('Booking Reference', widget.booking.bookingReference),
            _buildInfoRow('Booking Date', _formatDateTime(widget.booking.createdAt!)),
            _buildInfoRow('Status', widget.booking.bookingStatus.toString().split('.').last.toUpperCase(),
                statusColor: _getStatusColor(widget.booking.bookingStatus)),
            _buildInfoRow('Total Amount', 'LKR ${widget.booking.totalAmount.toStringAsFixed(2)}',
                valueColor: Colors.orange[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Journey Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBusTypeColor(widget.booking.busTimeTable.busType),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.booking.busTimeTable.busType,
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
            _buildInfoRow('Route', '${widget.booking.busTimeTable.from} → ${widget.booking.busTimeTable.to}'),
            _buildInfoRow('Departure', '${widget.booking.busTimeTable.startTime} - ${_formatDate(widget.booking.journeyDate)}'),
            _buildInfoRow('Arrival', widget.booking.busTimeTable.endTime),
            _buildInfoRow('Journey Date', _formatDate(widget.booking.journeyDate)),
            _buildInfoRow('Selected Seats', widget.booking.seatNumbers.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', widget.booking.passenger.fullName ?? 'N/A'),
            _buildInfoRow('Email', widget.booking.passenger.email ?? 'N/A'),
            _buildInfoRow('Phone', widget.booking.passenger.phone ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
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
            if (_isLoadingPayment)
              const Center(child: CircularProgressIndicator())
            else if (_paymentError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _paymentError!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_payment != null)
              Column(
                children: [
                  _buildInfoRow('Payment Method', _payment!.paymentMethod.toUpperCase()),
                  _buildInfoRow('Amount', 'LKR ${_payment!.amount.toStringAsFixed(2)}',
                      valueColor: Colors.orange[700]),
                  _buildInfoRow('Currency', _payment!.currency),
                  _buildInfoRow('Status', _payment!.paymentStatus.toString().split('.').last.toUpperCase(),
                      statusColor: _getPaymentStatusColor(_payment!.paymentStatus)),
                  if (_payment!.transactionId != null)
                    _buildInfoRow('Transaction ID', _payment!.transactionId!),
                  if (_payment!.paidAt != null)
                    _buildInfoRow('Paid At', _formatDateTime(_payment!.paidAt!)),
                ],
              )
            else
              const Text('No payment information available'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                color: valueColor ?? statusColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.pending;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
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

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
