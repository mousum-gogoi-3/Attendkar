import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/subject.dart';
import '../models/daily_sheet.dart';
import '../models/attendance_status.dart';
import '../models/university_closed_day.dart';
import '../models/semester.dart';

class HiveService {
  static const String boxUserProfile = 'userProfileBox';
  static const String boxSubjects = 'subjectsBox';
  static const String boxDailySheets = 'dailySheetsBox';
  static const String boxUniversityClosed = 'universityClosedBox';
  static const String boxSemesters = 'semestersBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SubjectAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DailySheetAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AttendanceStatusAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UniversityClosedDayAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(SemesterAdapter());

    // Open boxes
    await Hive.openBox<UserProfile>(boxUserProfile);
    await Hive.openBox<Subject>(boxSubjects);
    await Hive.openBox<DailySheet>(boxDailySheets);
    await Hive.openBox<UniversityClosedDay>(boxUniversityClosed);
    await Hive.openBox<Semester>(boxSemesters);
  }

  static Box<UserProfile> getUserProfileBox() => Hive.box<UserProfile>(boxUserProfile);
  static Box<Subject> getSubjectsBox() => Hive.box<Subject>(boxSubjects);
  static Box<DailySheet> getDailySheetsBox() => Hive.box<DailySheet>(boxDailySheets);
  static Box<UniversityClosedDay> getUniversityClosedBox() => Hive.box<UniversityClosedDay>(boxUniversityClosed);
  static Box<Semester> getSemestersBox() => Hive.box<Semester>(boxSemesters);
  
  static bool isFirstTimeUser() {
    return getUserProfileBox().isEmpty;
  }
}
