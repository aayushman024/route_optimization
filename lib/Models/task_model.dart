class TaskModel {
  final String id;
  final String feName;
  final String feEmpId;
  final String clientId;
  final String clientName;
  final String clientAddress;
  final String clientContactNumber;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final bool isCompleted;
  final bool onHold;
  final String locationUrl;
  final String purposeOfVisit;
  final int priority;
  final DateTime actualVisitStart;
  final DateTime actualVisitEnd;
  final int order;
  final String taskStatus;

  TaskModel({
    required this.id,
    required this.feName,
    required this.feEmpId,
    required this.clientId,
    required this.clientName,
    required this.clientAddress,
    required this.clientContactNumber,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.isCompleted,
    required this.onHold,
    required this.locationUrl,
    required this.purposeOfVisit,
    required this.priority,
    required this.actualVisitStart,
    required this.actualVisitEnd,
    required this.order,
    required this.taskStatus,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? '',
      feName: json['feName'] ?? '',
      feEmpId: json['feEmpId'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      clientAddress: json['clientAddress'] ?? '',
      clientContactNumber: json['clientContactNumber'] ?? '',
      availabilityStart: DateTime.parse(json['clientAvailability']['start']),
      availabilityEnd: DateTime.parse(json['clientAvailability']['end']),
      isCompleted: json['isCompleted'] ?? false,
      onHold: json['onHold'] ?? false,
      locationUrl: json['locationUrl'] ?? '',
      purposeOfVisit: json['purposeOfVisit'] ?? '',
      priority: json['priority'] ?? 0,
      actualVisitStart: DateTime.parse(json['actualVisitStart']),
      actualVisitEnd: DateTime.parse(json['actualVisitEnd']),
      order: json['order'] ?? 0,
      taskStatus: json['taskStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'feName': feName,
      'feEmpId': feEmpId,
      'clientId': clientId,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'clientContactNumber': clientContactNumber,
      'clientAvailability': {
        'start': availabilityStart.toIso8601String(),
        'end': availabilityEnd.toIso8601String(),
      },
      'isCompleted': isCompleted,
      'onHold': onHold,
      'locationUrl': locationUrl,
      'purposeOfVisit': purposeOfVisit,
      'priority': priority,
      'actualVisitStart': actualVisitStart.toIso8601String(),
      'actualVisitEnd': actualVisitEnd.toIso8601String(),
      'order': order,
      'taskStatus': taskStatus,
    };
  }
}
