import 'package:hive/hive.dart';

class Subject {
  String id;
  String name;
  String semesterId; // Links subject to a semester
  bool isActive;

  Subject({
    required this.id,
    required this.name,
    required this.semesterId,
    this.isActive = true,
  });
}

class SubjectAdapter extends TypeAdapter<Subject> {
  @override
  final int typeId = 1;

  @override
  Subject read(BinaryReader reader) {
    // For backwards compatibility during migration, we check available fields
    return Subject(
      id: reader.readString(),
      name: reader.readString(),
      isActive: reader.readBool(),
      // Read semesterId if it exists (newer version), else default to empty string which we'll migrate later
      semesterId: reader.availableBytes > 0 ? reader.readString() : '',
    );
  }

  @override
  void write(BinaryWriter writer, Subject obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeBool(obj.isActive);
    writer.writeString(obj.semesterId);
  }
}
