import 'package:frontend/models/bus_timetable.dart';
import 'package:frontend/models/payment.dart';

class Booking {
  final String? id;
  final String passengerId;
  final Passenger passenger;
  final BusTimeTable busTimeTable;
  final DateTime journeyDate;
  final List<String> seatNumbers;
  final String bookingReference;
  final double totalAmount;
  final BookingStatus bookingStatus;
  final PaymentStatus paymentStatus;
  final Payment? payment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Booking({
    this.id,
    required this.passengerId,
    required this.passenger,
    required this.busTimeTable,
    required this.journeyDate,
    required this.seatNumbers,
    required this.bookingReference,
    required this.totalAmount,
    this.bookingStatus = BookingStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.payment,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      print('Booking.fromJson: Parsing booking data');
      
      // Handle passengerId - it can be either a string ID or a populated object
      String passengerId;
      Map<String, dynamic> passengerData;
      
      if (json['passengerId'] is Map) {
        passengerData = json['passengerId'] as Map<String, dynamic>;
        passengerId = passengerData['id'] ?? passengerData['_id'] ?? '';
        print('Booking.fromJson: passengerId from object: $passengerId');
      } else {
        passengerId = json['passengerId']?.toString() ?? '';
        passengerData = {};
        print('Booking.fromJson: passengerId from string: $passengerId');
      }

      // Handle timetableId - it can be either a string ID or a populated object
      Map<String, dynamic> timetableData;
      if (json['timetableId'] is Map) {
        timetableData = json['timetableId'] as Map<String, dynamic>;
        print('Booking.fromJson: timetableId from object');
      } else {
        timetableData = {};
        print('Booking.fromJson: timetableId from string');
      }

      print('Booking.fromJson: Creating Passenger object');
      final passenger = Passenger.fromJson(passengerData);
      
      print('Booking.fromJson: Creating BusTimeTable object');
      final busTimeTable = BusTimeTable.fromJson(timetableData);
      
      print('Booking.fromJson: Parsing journeyDate: ${json['journeyDate']}');
      final journeyDate = DateTime.parse(json['journeyDate']);
      
      print('Booking.fromJson: Parsing seatNumbers: ${json['seatNumbers']}');
      final seatNumbers = List<String>.from(json['seatNumbers'] ?? []);
      
      print('Booking.fromJson: Parsing bookingReference: ${json['bookingReference']}');
      final bookingReference = json['bookingReference'] ?? '';
      
      print('Booking.fromJson: Parsing totalAmount from pricing');
      final totalAmount = json['pricing'] != null && json['pricing'] is Map
          ? (json['pricing']['totalAmount'] as num).toDouble()
          : 0.0;
      
      print('Booking.fromJson: Creating Booking object');
      final booking = Booking(
        id: json['_id'] ?? json['id'],
        passengerId: passengerId,
        passenger: passenger,
        busTimeTable: busTimeTable,
        journeyDate: journeyDate,
        seatNumbers: seatNumbers,
        bookingReference: bookingReference,
        totalAmount: totalAmount,
        bookingStatus: BookingStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['bookingStatus'],
          orElse: () => BookingStatus.pending,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['paymentStatus'],
          orElse: () => PaymentStatus.pending,
        ),
        payment: json['payment'] != null && json['payment'] is Map
            ? Payment.fromJson(json['payment'])
            : null,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      );
      
      print('Booking.fromJson: Successfully created booking');
      return booking;
    } catch (e, stackTrace) {
      print('Booking.fromJson: Error parsing booking: $e');
      print('Booking.fromJson: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'passenger': passengerId,
      'busTimeTable': busTimeTable.toJson(),
      'journeyDate': journeyDate.toIso8601String(),
      'seatNumbers': seatNumbers,
      'bookingReference': bookingReference,
      'totalAmount': totalAmount,
      'bookingStatus': bookingStatus.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      if (payment != null) 'payment': payment!.toJson(),
    };
  }
}

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
}

class SeatInfo {
  final String seatNumber;
  final bool isBooked;
  final bool isAvailable;

  SeatInfo({
    required this.seatNumber,
    required this.isBooked,
    required this.isAvailable,
  });

  factory SeatInfo.fromJson(Map<String, dynamic> json) {
    return SeatInfo(
      seatNumber: json['seatNumber'],
      isBooked: json['isBooked'],
      isAvailable: json['isAvailable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seatNumber': seatNumber,
      'isBooked': isBooked,
      'isAvailable': isAvailable,
    };
  }
}

class SeatAvailability {
  final int totalSeats;
  final int availableSeats;
  final List<String> bookedSeats;
  final List<List<SeatInfo>> seatMap;

  SeatAvailability({
    required this.totalSeats,
    required this.availableSeats,
    required this.bookedSeats,
    required this.seatMap,
  });

  factory SeatAvailability.fromJson(Map<String, dynamic> json) {
    return SeatAvailability(
      totalSeats: json['totalSeats'],
      availableSeats: json['availableSeats'],
      bookedSeats: List<String>.from(json['bookedSeats']),
      seatMap: (json['seatMap'] as List)
          .map((row) => (row as List)
              .map((seatJson) => SeatInfo.fromJson(seatJson))
              .toList())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'bookedSeats': bookedSeats,
      'seatMap': seatMap
          .map((row) => row.map((seatInfo) => seatInfo.toJson()).toList())
          .toList(),
    };
  }
}

class Passenger {
  final String? id;
  final String fullName;
  final String email;
  final String phone;

  Passenger({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
    };
  }
}