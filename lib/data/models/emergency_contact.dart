import 'package:hive/hive.dart';

part 'emergency_contact.g.dart';

@HiveType(typeId: 0)
class EmergencyContact extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String phone;

  @HiveField(3)
  late String role; // 'family', 'rescue', 'sar', 'friend'

  @HiveField(4)
  late bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.isPrimary = false,
  });
}
