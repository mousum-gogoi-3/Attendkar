import 'package:hive/hive.dart';

class Semester {
  String id;
  String name;

  Semester({
    required this.id,
    required this.name,
  });
}

class SemesterAdapter extends TypeAdapter<Semester> {
  @override
  final int typeId = 5;

  @override
  Semester read(BinaryReader reader) {
    return Semester(
      id: reader.readString(),
      name: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Semester obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
  }
}
