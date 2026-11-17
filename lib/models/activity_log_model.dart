enum ActivityAction { created, updated, deleted }

enum ActivityEntity { transaction, product, category, member }

class ActivityDetail {
  final String label;
  final String value;
  final String? oldValue;

  const ActivityDetail(this.label, this.value, {this.oldValue});

  const ActivityDetail.change(this.label, String from, String to) : value = to, oldValue = from;

  bool get isChange => oldValue != null;

  String get summary => isChange ? '$label: $oldValue → $value' : '$label: $value';
}

class ActivityLogModel {
  final String id;
  final String actorName;
  final String actorRole;
  final ActivityAction action;
  final ActivityEntity entity;
  final String subject;
  final List<ActivityDetail> details;
  final String description;
  final DateTime timestamp;

  const ActivityLogModel({
    required this.id,
    required this.actorName,
    this.actorRole = '',
    required this.action,
    required this.entity,
    this.subject = '',
    this.details = const [],
    required this.description,
    required this.timestamp,
  });

  String get searchText =>
      [actorName, subject, description, for (final d in details) d.summary].join(' ').toLowerCase();
}
