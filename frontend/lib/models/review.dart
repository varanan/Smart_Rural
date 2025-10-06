class Review {
  final String id;
  final String busId;
  final String passengerId;
  final String? passengerName;
  final int rating;
  final String comment;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BusInfo? busInfo;

  Review({
    required this.id,
    required this.busId,
    required this.passengerId,
    this.passengerName,
    required this.rating,
    required this.comment,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.busInfo,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? json['_id'] ?? '',
      busId: json['busId'] is String ? json['busId'] : (json['busId']?['_id'] ?? ''),
      passengerId: json['passengerId'] is String 
          ? json['passengerId'] 
          : (json['passengerId']?['_id'] ?? ''),
      passengerName: json['passengerId'] is Map 
          ? json['passengerId']['fullName'] 
          : null,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      busInfo: json['busId'] is Map ? BusInfo.fromJson(json['busId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class BusInfo {
  final String from;
  final String to;
  final String busType;
  final String? startTime;
  final String? endTime;

  BusInfo({
    required this.from,
    required this.to,
    required this.busType,
    this.startTime,
    this.endTime,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      busType: json['busType'] ?? '',
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}