import 'package:hive/hive.dart';

@HiveType(typeId: 3)
enum AttendanceStatus {
  @HiveField(0)
  unselected,
  @HiveField(1)
  present,
  @HiveField(2)
  absent,
  @HiveField(3)
  classNotTaken,
  @HiveField(4)
  noClass
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 3;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.unselected;
      case 1:
        return AttendanceStatus.present;
      case 2:
        return AttendanceStatus.absent;
      case 3:
        return AttendanceStatus.classNotTaken;
      case 4:
        return AttendanceStatus.noClass;
      default:
        return AttendanceStatus.unselected;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.unselected:
        writer.writeByte(0);
        break;
      case AttendanceStatus.present:
        writer.writeByte(1);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(2);
        break;
      case AttendanceStatus.classNotTaken:
        writer.writeByte(3);
        break;
      case AttendanceStatus.noClass:
        writer.writeByte(4);
        break;
    }
  }
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.classNotTaken:
        return 'Class Not Taken';
      case AttendanceStatus.noClass:
        return 'No Class';
      case AttendanceStatus.unselected:
        return 'Not Marked';
    }
  }
}
