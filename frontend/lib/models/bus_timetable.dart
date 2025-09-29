class BusTimeTable {
  final String? id;
  final String from;
  final String to;
  final String startTime;
  final String endTime;
  final String busType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BusTimeTable({
    this.id,
    required this.from,
    required this.to,
    required this.startTime,
    required this.endTime,
    required this.busType,
    this.createdAt,
    this.updatedAt,
  });

  factory BusTimeTable.fromJson(Map<String, dynamic> json) {
    return BusTimeTable(
      id: json['_id'] ?? json['id'],
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      busType: json['busType'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'from': from,
      'to': to,
      'startTime': startTime,
      'endTime': endTime,
      'busType': busType,
    };
  }

  BusTimeTable copyWith({
    String? id,
    String? from,
    String? to,
    String? startTime,
    String? endTime,
    String? busType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusTimeTable(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      busType: busType ?? this.busType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum BusType {
  express('Express'),
  normal('Normal'),
  luxury('Luxury'),
  semiLuxury('Semi-Luxury'),
  intercity('Intercity');

  const BusType(this.displayName);
  final String displayName;

  static BusType fromString(String value) {
    return BusType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BusType.normal,
    );
  }
}