import 'package:flutter/material.dart';
import '../../models/bus_timetable.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import 'booking_form_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final BusTimeTable busTimeTable;
  final DateTime travelDate;

  const SeatSelectionScreen({
    Key? key,
    required this.busTimeTable,
    required this.travelDate,
  }) : super(key: key);

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  AvailableSeats? availableSeats;
  int? selectedSeat;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadAvailableSeats();
  }

  Future<void> _loadAvailableSeats() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print('🔍 Loading seats for bus: ${widget.busTimeTable.id}');
      print('📅 Travel date: ${widget.travelDate}');

      final result = await ApiService.getAvailableSeats(
        busId: widget.busTimeTable.id!,
        travelDate: widget.travelDate,
      );

      print('📡 API Response: $result');

      if (result['success']) {
        setState(() {
          availableSeats = AvailableSeats.fromJson(result['data']);
          isLoading = false;
        });
        print(
          '✅ Seats loaded successfully: ${availableSeats?.availableSeats.length} available',
        );
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load available seats';
          isLoading = false;
        });
        print('❌ Failed to load seats: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading seats: ${e.toString()}';
        isLoading = false;
      });
      print('💥 Exception loading seats: $e');
    }
  }

  void _selectSeat(int seatNumber) {
    if (availableSeats?.availableSeats.contains(seatNumber) == true) {
      setState(() {
        selectedSeat = seatNumber;
      });
      print('🪑 Selected seat: $seatNumber');
    } else {
      print('❌ Cannot select seat $seatNumber - not available');
    }
  }

  void _proceedToBooking() {
    if (selectedSeat != null && availableSeats != null) {
      print('➡️ Proceeding to booking with seat: $selectedSeat');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingFormScreen(
            busTimeTable: widget.busTimeTable,
            travelDate: widget.travelDate,
            seatNumber: selectedSeat!,
            fare: availableSeats!.fare,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Seat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading available seats...'),
                ],
              ),
            )
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAvailableSeats,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      print('🔍 Debug Info:');
                      print('Bus ID: ${widget.busTimeTable.id}');
                      print('Travel Date: ${widget.travelDate}');
                      print('Bus Details: ${widget.busTimeTable.toJson()}');
                    },
                    child: const Text('Show Debug Info'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Bus info card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.busTimeTable.from} → ${widget.busTimeTable.to}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.busTimeTable.startTime} - ${widget.busTimeTable.endTime}',
                        ),
                        Text('Bus Type: ${widget.busTimeTable.busType}'),
                        Text(
                          'Travel Date: ${widget.travelDate.toString().split(' ')[0]}',
                        ),
                        Text(
                          'Fare: Rs. ${availableSeats?.fare.toStringAsFixed(2)}',
                        ),
                        if (availableSeats != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Total Seats: ${availableSeats!.totalSeats}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Available: ${availableSeats!.availableSeats.length} seats',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.green, 'Available'),
                      _buildLegendItem(Colors.red, 'Booked'),
                      _buildLegendItem(Colors.blue, 'Selected'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Seat layout
                Expanded(
                  child: availableSeats != null
                      ? _buildSeatLayout()
                      : const Center(child: Text('No seat data available')),
                ),

                // Proceed button
                if (selectedSeat != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _proceedToBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Book Seat $selectedSeat - Rs. ${availableSeats?.fare.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatLayout() {
    final totalSeats = availableSeats!.totalSeats;
    final seatsPerRow = 4; // 2 seats on each side of the aisle
    final rows = (totalSeats / seatsPerRow).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Driver section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Driver',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Seats
          ...List.generate(rows, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Left side seats
                  ...List.generate(2, (seatIndex) {
                    final seatNumber = rowIndex * seatsPerRow + seatIndex + 1;
                    if (seatNumber > totalSeats) return const SizedBox.shrink();
                    return _buildSeat(seatNumber);
                  }),

                  // Aisle
                  const SizedBox(width: 32),

                  // Right side seats
                  ...List.generate(2, (seatIndex) {
                    final seatNumber = rowIndex * seatsPerRow + seatIndex + 3;
                    if (seatNumber > totalSeats) return const SizedBox.shrink();
                    return _buildSeat(seatNumber);
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeat(int seatNumber) {
    final isAvailable = availableSeats!.availableSeats.contains(seatNumber);
    final isSelected = selectedSeat == seatNumber;
    final isBooked = availableSeats!.bookedSeats.contains(seatNumber);

    Color seatColor;
    if (isSelected) {
      seatColor = Colors.blue;
    } else if (isBooked) {
      seatColor = Colors.red;
    } else if (isAvailable) {
      seatColor = Colors.green;
    } else {
      seatColor = Colors.grey;
    }

    return GestureDetector(
      onTap: isAvailable ? () => _selectSeat(seatNumber) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Center(
          child: Text(
            seatNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
