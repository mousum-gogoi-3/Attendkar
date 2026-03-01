import 'package:hive/hive.dart';

class UserProfile {
  String name;
  String course;
  String rollNumber;
  bool isDarkMode;
  String? activeSemesterId; // Currently active semester

  UserProfile({
    required this.name,
    required this.course,
    required this.rollNumber,
    this.isDarkMode = false,
    this.activeSemesterId,
  });
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    return UserProfile(
      name: reader.readString(),
      course: reader.readString(),
      rollNumber: reader.readString(),
      isDarkMode: reader.readBool(),
      activeSemesterId: reader.availableBytes > 0 ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.course);
    writer.writeString(obj.rollNumber);
    writer.writeBool(obj.isDarkMode);
    writer.writeString(obj.activeSemesterId ?? '');
  }
}
