import 'package:hive/hive.dart';

part 'activity_log.g.dart';

enum LogLevel { info, warning, critical, success }

@HiveType(typeId: 1)
class ActivityLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String message;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late String level; // info, warning, critical, success

  ActivityLog({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.level,
  });

  LogLevel get logLevel {
    switch (level) {
      case 'critical': return LogLevel.critical;
      case 'warning':  return LogLevel.warning;
      case 'success':  return LogLevel.success;
      default:         return LogLevel.info;
    }
  }
}
