class FEComment {
  final String text;
  final String byName;
  final DateTime? createdAt;

  FEComment({
    required this.text,
    required this.byName,
    this.createdAt,
  });

  factory FEComment.fromJson(Map<String, dynamic> json) {
    return FEComment(
      text: json['text'] ?? '',
      byName: json['byName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'byName': byName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class TaskModel {
  final String taskId;
  final String clientId;
  final String clientName;
  final String clientContact;
  final String visitingAddress;
  final String? additionalAddressDetails;
  final DateTime availabilityStart;
  final DateTime availabilityEnd;
  final int priority;
  final bool isCompleted;
  final bool onHold;
  final int order;
  final String status;
  final bool canGoAnytime;
  final String feId;
  final String feName;
  final String purposeOfVisit;
  final String locationString;
  final List<FEComment> feComments;
  final List<String> completionImages;
  final DateTime? completedAtTime;

  TaskModel({
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.clientContact,
    required this.visitingAddress,
    required this.additionalAddressDetails,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.priority,
    required this.isCompleted,
    required this.onHold,
    required this.order,
    required this.status,
    required this.canGoAnytime,
    required this.feId,
    required this.feName,
    required this.purposeOfVisit,
    required this.locationString,
    this.feComments = const [],
    this.completionImages = const [],
    this.completedAtTime,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['visitId'] ?? json['_id'] ?? '',
      clientId: json['clientId'] is Map
          ? (json['clientId']['_id'] ?? '')
          : (json['clientId'] ?? ''),
      clientName: json['clientId'] is Map
          ? (json['clientId']['name'] ?? '')
          : (json['clientName'] ?? ''),
      clientContact: json['clientId'] is Map
          ? (json['clientId']['contactNumber'] ?? '')
          : (json['clientContact'] ?? ''),
      visitingAddress: json['visitingAddress'] ?? '',
      additionalAddressDetails: json['additionalAddressDetails']?.toString(),
      availabilityStart: DateTime.parse(json['availability']['start']),
      availabilityEnd: DateTime.parse(json['availability']['end']),
      priority: json['priority'] is String
          ? (json['priority'] == 'High' ? 1 : json['priority'] == 'Low' ? 3 : 2)
          : (json['priority'] ?? 0),
      isCompleted: json['isCompleted'] ?? false,
      onHold: json['onHold'] ?? false,
      order: json['order'] ?? 0,
      status: json['status'] ?? '',
      canGoAnytime: json['canGoAnytime'] ?? false,
      feId: json['feId'] ?? '',
      feName: json['feName'] ?? '',
      purposeOfVisit: json['purposeOfVisit'] ?? '',
      locationString: json['locationString'] ?? '',
      feComments: (json['feComments'] as List?)
              ?.map((e) => FEComment.fromJson(e))
              .toList() ??
          [],
      completionImages: (json['completionImages'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedAtTime: json['completedAtTime'] != null
          ? DateTime.tryParse(json['completedAtTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visitId': taskId,
      'clientId': clientId,
      'clientName': clientName,
      'clientContact': clientContact,
      'visitingAddress': visitingAddress,
      'additionalAddressDetails': additionalAddressDetails,
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
      'feComments': feComments.map((e) => e.toJson()).toList(),
      'completionImages': completionImages,
      'completedAtTime': completedAtTime?.toIso8601String(),
    };
  }
}
