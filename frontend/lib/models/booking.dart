class Booking {
  final String? id;
  final String busId;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final int seatNumber;
  final DateTime bookingDate;
  final DateTime travelDate;
  final String status;
  final double fare;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BusInfo? busInfo;

  Booking({
    this.id,
    required this.busId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seatNumber,
    required this.bookingDate,
    required this.travelDate,
    required this.status,
    required this.fare,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.busInfo,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      busId: json['busId'] is String
          ? json['busId']
          : (json['busId']?['_id'] ?? ''),
      passengerId: json['passengerId'] ?? '',
      passengerName: json['passengerName'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      seatNumber: json['seatNumber'] ?? 0,
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      travelDate: json['travelDate'] != null
          ? DateTime.parse(json['travelDate'])
          : DateTime.now(),
      status: json['status'] ?? 'confirmed',
      fare: (json['fare'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      busInfo: json['busId'] is Map ? BusInfo.fromJson(json['busId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'seatNumber': seatNumber,
      'travelDate': travelDate.toIso8601String(),
    };
  }
}

class BusInfo {
  final String from;
  final String to;
  final String startTime;
  final String endTime;
  final String busType;

  BusInfo({
    required this.from,
    required this.to,
    required this.startTime,
    required this.endTime,
    required this.busType,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      busType: json['busType'] ?? '',
    );
  }
}

class AvailableSeats {
  final int totalSeats;
  final List<int> bookedSeats;
  final List<int> availableSeats;
  final double fare;

  AvailableSeats({
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
    required this.fare,
  });

  factory AvailableSeats.fromJson(Map<String, dynamic> json) {
    return AvailableSeats(
      totalSeats: json['totalSeats'] ?? 0,
      bookedSeats: List<int>.from(json['bookedSeats'] ?? []),
      availableSeats: List<int>.from(json['availableSeats'] ?? []),
      fare: (json['fare'] ?? 0).toDouble(),
    );
  }
}
