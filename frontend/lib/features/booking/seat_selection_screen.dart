import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/bus_timetable.dart';
import '../../services/api_service.dart';
import '../../widgets/seat_map_widget.dart';

class SeatSelectionScreen extends StatefulWidget {
  final BusTimeTable timetable;
  final String journeyDate;

  const SeatSelectionScreen({
    Key? key,
    required this.timetable,
    required this.journeyDate,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  SeatAvailability? _seatAvailability;
  List<String> _selectedSeats = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _pricingInfo;
  bool _isPricingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSeatAvailability();
    _loadPricing();
  }

  Future<void> _loadSeatAvailability() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await ApiService.getSeatAvailability(
        timetableId: widget.timetable.id!,
        journeyDate: widget.journeyDate,
      );

      if (response['success']) {
        setState(() {
          _seatAvailability = SeatAvailability.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load seat availability';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading seat availability: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPricing() async {
    try {
      setState(() {
        _isPricingLoading = true;
      });

      print('[SeatSelection] Loading pricing for: ${widget.timetable.from} → ${widget.timetable.to}, ${widget.timetable.busType}, ${widget.journeyDate}');

      final response = await ApiService.getPriceEstimation(
        from: widget.timetable.from,
        to: widget.timetable.to,
        busType: widget.timetable.busType,
        journeyDate: widget.journeyDate,
        seatCount: 1,
      );

      print('[SeatSelection] Pricing API response: $response');

      if (response['success']) {
        setState(() {
          _pricingInfo = response['data'];
          _isPricingLoading = false;
        });
        print('[SeatSelection] Pricing loaded successfully: ${_pricingInfo?['pricePerSeat']}');
      } else {
        print('[SeatSelection] Pricing API failed: ${response['message']}');
        setState(() {
          _isPricingLoading = false;
        });
      }
    } catch (e) {
      print('[SeatSelection] Pricing API error: $e');
      setState(() {
        _isPricingLoading = false;
      });
    }
  }

  void _onSeatsChanged(List<String> selectedSeats) {
    setState(() {
      _selectedSeats = selectedSeats;
    });
  }

  void _proceedToPassengerDetails() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one seat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Always use the dynamic pricing calculation
    double pricePerSeat = _calculatePricePerSeat();

    Navigator.pushNamed(
      context,
      '/passenger-details',
      arguments: {
        'timetable': widget.timetable,
        'journeyDate': widget.journeyDate,
        'selectedSeats': _selectedSeats,
        'pricePerSeat': pricePerSeat,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seats'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            onPressed: _loadSeatAvailability,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_seatAvailability == null) return const SizedBox();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRouteInfo(),
                const SizedBox(height: 24),
                _buildSeatMap(),
                const SizedBox(height: 24),
                _buildPricingInfo(),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Card(
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
                const Spacer(),
                Text(
                  '${widget.timetable.from} → ${widget.timetable.to}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                      'Departure',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      widget.timetable.startTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arrival',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      widget.timetable.endTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _formatDate(widget.journeyDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatMap() {
    return SeatMapWidget(
      seatAvailability: _seatAvailability!,
      selectedSeats: _selectedSeats,
      onSeatsChanged: _onSeatsChanged,
      maxSeatsPerBooking: 10,
    );
  }

  Widget _buildPricingInfo() {
    if (_selectedSeats.isEmpty) {
      return const SizedBox();
    }

    double pricePerSeat = _calculatePricePerSeat();
    double totalAmount = pricePerSeat * _selectedSeats.length;

    if (_pricingInfo != null && !_isPricingLoading) {
      pricePerSeat = (_pricingInfo!['pricePerSeat'] as num).toDouble();
      totalAmount = pricePerSeat * _selectedSeats.length;
    }

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isPricingLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pricingInfo != null && _pricingInfo!['route'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Distance', style: TextStyle(color: Colors.grey)),
                  Text('${_pricingInfo!['route']['distance']} km'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bus Type', style: TextStyle(color: Colors.grey)),
                  Text(widget.timetable.busType),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selected Seats (${_selectedSeats.length})'),
                Text(_selectedSeats.join(', ')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price per seat'),
                Text('LKR ${pricePerSeat.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'LKR ${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            if (_pricingInfo != null && _pricingInfo!['timeMultipliers'] != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'Pricing Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              if (_pricingInfo!['timeMultipliers']['isPeakHour'] == true)
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    const Text(
                      'Peak Hour Pricing Applied',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              if (_pricingInfo!['timeMultipliers']['isWeekend'] == true)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    const Text(
                      'Weekend Pricing Applied',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              if (_pricingInfo!['timeMultipliers']['isHoliday'] == true)
                Row(
                  children: [
                    Icon(Icons.celebration, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    const Text(
                      'Holiday Pricing Applied',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Selected: ${_selectedSeats.length} seat(s)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _selectedSeats.isNotEmpty ? _proceedToPassengerDetails : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Continue'),
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

  double _calculatePricePerSeat() {
    // Use dynamic pricing if available, otherwise fallback to basic pricing
    if (_pricingInfo != null && !_isPricingLoading) {
      return (_pricingInfo!['pricePerSeat'] as num).toDouble();
    }
    
    // Fallback to basic pricing based on bus type (should rarely be used)
    switch (widget.timetable.busType) {
      case 'Normal':
        return 100.0;
      case 'Express':
        return 130.0;
      case 'Luxury':
        return 200.0;
      case 'Semi-Luxury':
        return 150.0;
      case 'Intercity':
        return 120.0;
      default:
        return 100.0;
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
