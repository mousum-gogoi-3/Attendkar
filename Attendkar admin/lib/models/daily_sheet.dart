import 'package:hive/hive.dart';
import 'attendance_status.dart';

class DailySheet {
  String semesterId; // Links daily sheet to a specific semester
  String date; // Format: yyyy-MM-dd
  bool isClosed;
  String reason;
  Map<String, AttendanceStatus> subjectStatuses; // Subject ID -> AttendanceStatus

  DailySheet({
    required this.semesterId,
    required this.date,
    this.isClosed = false,
    this.reason = '',
    Map<String, AttendanceStatus>? subjectStatuses,
  }) : subjectStatuses = subjectStatuses ?? <String, AttendanceStatus>{};
}

class DailySheetAdapter extends TypeAdapter<DailySheet> {
  @override
  final int typeId = 2;

  @override
  DailySheet read(BinaryReader reader) {
    final date = reader.readString();
    final isClosed = reader.readBool();
    final reason = reader.readString();
    final balances = reader.readMap();
    final semesterId = reader.availableBytes > 0 ? reader.readString() : '';
    
    return DailySheet(
      semesterId: semesterId,
      date: date,
      isClosed: isClosed,
      reason: reason,
      subjectStatuses: balances.cast<String, AttendanceStatus>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailySheet obj) {
    writer.writeString(obj.date);
    writer.writeBool(obj.isClosed);
    writer.writeString(obj.reason);
    writer.writeMap(obj.subjectStatuses);
    writer.writeString(obj.semesterId);
  }
}
