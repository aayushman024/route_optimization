class TaskModel {
  final String taskId;
  final String clientId;
  final String clientName;
  final String clientContact;
  final String visitingAddress;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final int priority;
  final bool isCompleted;
  final bool onHold;
  final int order;
  final String status;
  final String feId;
  final String feName;
  final String purposeOfVisit;
  final String locationString;

  TaskModel({
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.clientContact,
    required this.visitingAddress,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.priority,
    required this.isCompleted,
    required this.onHold,
    required this.order,
    required this.status,
    required this.feId,
    required this.feName,
    required this.purposeOfVisit,
    required this.locationString,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['visitId'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      clientContact: json['clientContact'] ?? '',
      visitingAddress: json['visitingAddress'] ?? '',
      availabilityStart: DateTime.parse(json['availability']['start']),
      availabilityEnd: DateTime.parse(json['availability']['end']),
      priority: json['priority'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      onHold: json['onHold'] ?? false,
      order: json['order'] ?? 0,
      status: json['status'] ?? '',
      feId: json['feId'] ?? '',
      feName: json['feName'] ?? '',
      purposeOfVisit: json['purposeOfVisit'] ?? '',
      locationString: json['locationString'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitId': taskId,
      'clientId': clientId,
      'clientName': clientName,
      'clientContact': clientContact,
      'visitingAddress': visitingAddress,
      'availability': {
        'start': availabilityStart.toIso8601String(),
        'end': availabilityEnd.toIso8601String(),
      },
      'priority': priority,
      'isCompleted': isCompleted,
      'onHold': onHold,
      'order': order,
      'status': status,
      'feId': feId,
      'feName': feName,
      'purposeOfVisit': purposeOfVisit,
      'locationString': locationString,
    };
  }
}
