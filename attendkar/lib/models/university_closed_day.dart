import 'package:hive/hive.dart';

class UniversityClosedDay {
  String id;
  String date; // Format: yyyy-MM-dd
  String? reason;

  UniversityClosedDay({
    required this.id,
    required this.date,
    this.reason,
  });
}

class UniversityClosedDayAdapter extends TypeAdapter<UniversityClosedDay> {
  @override
  final int typeId = 4;

  @override
  UniversityClosedDay read(BinaryReader reader) {
    return UniversityClosedDay(
      id: reader.readString(),
      date: reader.readString(),
      reason: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, UniversityClosedDay obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.date);
    writer.writeString(obj.reason ?? '');
  }
}
