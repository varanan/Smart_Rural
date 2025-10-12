class RideShare {
  final String id;
  final String from;
  final String to;
  final String startTime;
  final String vehicleType;
  final int seatCapacity;
  final double price;
  final bool isActive;
  final String createdBy;
  final List<RideRequest> requests;
  final int availableSeats;

  RideShare({
    required this.id,
    required this.from,
    required this.to,
    required this.startTime,
    required this.vehicleType,
    required this.seatCapacity,
    required this.price,
    required this.isActive,
    required this.createdBy,
    required this.requests,
    required this.availableSeats,
  });

  factory RideShare.fromJson(Map<String, dynamic> json) {
    return RideShare(
      id: json['_id'] ?? json['id'],
      from: json['from'],
      to: json['to'],
      startTime: json['startTime'],
      vehicleType: json['vehicleType'],
      seatCapacity: json['seatCapacity'],
      price: json['price'].toDouble(),
      isActive: json['isActive'],
      createdBy: (json['createdBy'] is String) 
        ? json['createdBy'] 
        : (json['createdBy'] is Map) 
            ? (json['createdBy']['id']?.toString() ?? json['createdBy']['_id']?.toString() ?? '')
            : '',
      requests: (json['requests'] as List?)
          ?.map((req) => RideRequest.fromJson(req))
          .toList() ?? [],
      availableSeats: json['availableSeats'],
    );
  }
}

class RideRequest {
  final String id;
  final String passengerId;
  final String status;
  final DateTime requestedAt;
  final Map<String, dynamic>? passengerDetails;

  RideRequest({
    required this.id,
    required this.passengerId,
    required this.status,
    required this.requestedAt,
    this.passengerDetails,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
  // Handle passenger field - it could be String ID or full Map object
  final passengerData = json['passenger'];
  
  String passengerId;
  Map<String, dynamic>? passengerDetails;
  
  if (passengerData is String) {
    passengerId = passengerData;
    passengerDetails = null;
  } else if (passengerData is Map) {
    passengerId = passengerData['_id']?.toString() ?? passengerData['id']?.toString() ?? '';
    passengerDetails = Map<String, dynamic>.from(passengerData);
  } else {
    passengerId = '';
    passengerDetails = null;
  }

  return RideRequest(
    id: json['_id'] ?? json['id'],
    passengerId: passengerId,
    status: json['status'],
    requestedAt: DateTime.parse(json['requestedAt']),
    passengerDetails: passengerDetails,
  );
}
}