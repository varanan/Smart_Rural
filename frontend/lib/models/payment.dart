class Payment {
  final String? id;
  final String bookingId;
  final String passengerId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String? transactionId;
  final PaymentStatus paymentStatus;
  final Map<String, dynamic>? paymentGatewayResponse;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    this.id,
    required this.bookingId,
    required this.passengerId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.transactionId,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentGatewayResponse,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'],
      bookingId: json['booking'] is Map ? json['booking']['_id'] : json['booking'],
      passengerId: json['passenger'] is Map ? json['passenger']['_id'] : json['passenger'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentGatewayResponse: json['paymentGatewayResponse'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'booking': bookingId,
      'passenger': passengerId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentGatewayResponse': paymentGatewayResponse,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}