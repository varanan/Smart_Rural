class NotificationModel {
  final String id;
  final String recipientId;
  final String recipientModel;
  final String? senderId;
  final String type;
  final String title;
  final String message;
  final String? relatedScheduleId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientModel,
    this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedScheduleId,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      recipientModel: json['recipientModel'] ?? '',
      senderId: json['senderId'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedScheduleId: json['relatedScheduleId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'recipientId': recipientId,
      'recipientModel': recipientModel,
      'senderId': senderId,
      'type': type,
      'title': title,
      'message': message,
      'relatedScheduleId': relatedScheduleId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}