import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/subject.dart';
import '../models/daily_sheet.dart';
import '../models/attendance_status.dart';
import '../models/university_closed_day.dart';
import '../models/semester.dart';
import '../services/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceProvider with ChangeNotifier {
  UserProfile? _userProfile;
  List<Semester> _semesters = [];
  List<Subject> _subjects = [];
  Map<String, DailySheet> _dailySheets = {};
  Map<String, UniversityClosedDay> _closedDays = {};

  bool _isDarkMode = false;

  UserProfile? get userProfile => _userProfile;
  bool get isDarkMode => _isDarkMode;
  List<Semester> get semesters => _semesters;
  
  // Only return subjects for the active semester
  List<Subject> get subjects {
    if (_userProfile?.activeSemesterId == null) return [];
    return _subjects.where((s) => s.semesterId == _userProfile!.activeSemesterId).toList();
  }

  // Only return daily sheets for the active semester
  Map<String, DailySheet> get dailySheets {
    if (_userProfile?.activeSemesterId == null) return {};
    return Map.fromEntries(
      _dailySheets.entries.where((e) => e.value.semesterId == _userProfile!.activeSemesterId)
    );
  }

  Map<String, UniversityClosedDay> get closedDays => _closedDays;

  AttendanceProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final userBox = HiveService.getUserProfileBox();
    if (userBox.isNotEmpty) {
      _userProfile = userBox.getAt(0);
    }
    
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    
    _semesters = HiveService.getSemestersBox().values.toList();
    _subjects = HiveService.getSubjectsBox().values.toList();
    
    final sheetsBox = HiveService.getDailySheetsBox();
    _dailySheets = { for (var sheet in sheetsBox.values) '${sheet.semesterId}_${sheet.date}' : sheet };

    final closedBox = HiveService.getUniversityClosedBox();
    _closedDays = { for (var closed in closedBox.values) closed.date : closed };

    await _performMigrationIfNeeded();

    _ensureTodaySheetExists();
    notifyListeners();
  }

  Future<void> _performMigrationIfNeeded() async {
    final semestersBox = HiveService.getSemestersBox();
    final userBox = HiveService.getUserProfileBox();
    final subjectsBox = HiveService.getSubjectsBox();
    final sheetsBox = HiveService.getDailySheetsBox();

    // If we have subjects or daily sheets, but no semesters, it means we need to migrate
    if (semestersBox.isEmpty && (subjectsBox.isNotEmpty || sheetsBox.isNotEmpty)) {
      // 1. Create a default Semester
      final defaultSemester = Semester(id: const Uuid().v4(), name: 'Semester 1');
      await semestersBox.put(defaultSemester.id, defaultSemester);
      _semesters.add(defaultSemester);

      // 2. Set Active Semester
      if (_userProfile != null) {
        _userProfile!.activeSemesterId = defaultSemester.id;
        await userBox.putAt(0, _userProfile!);
      }

      // 3. Migrate Subjects
      for (var subject in _subjects) {
        if (subject.semesterId.isEmpty) {
          subject.semesterId = defaultSemester.id;
          await subjectsBox.put(subject.id, subject);
        }
      }

      // 4. Migrate Daily Sheets
      List<DailySheet> oldSheets = sheetsBox.values.toList();
      await sheetsBox.clear(); // Clear old sheets
      _dailySheets.clear(); // Clear memory map

      for (var sheet in oldSheets) {
        // Only assign semesterId if it's empty (from old version)
        if (sheet.semesterId.isEmpty) {
          sheet.semesterId = defaultSemester.id;
        }
        String newKey = '${sheet.semesterId}_${sheet.date}';
        await sheetsBox.put(newKey, sheet);
        _dailySheets[newKey] = sheet;
      }
    } else if (semestersBox.isEmpty) {
       // Brand new user, create Semester 1 by default when they first launch
       final defaultSemester = Semester(id: const Uuid().v4(), name: 'Semester 1');
       await semestersBox.put(defaultSemester.id, defaultSemester);
       _semesters.add(defaultSemester);
       if (_userProfile != null) {
         _userProfile!.activeSemesterId = defaultSemester.id;
         await userBox.putAt(0, _userProfile!);
       }
    }
  }

  void _ensureTodaySheetExists() {
    if (_userProfile?.activeSemesterId == null) return;
    
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String sheetKey = '${_userProfile!.activeSemesterId}_$todayDate';

    if (!_dailySheets.containsKey(sheetKey)) {
      final newSheet = DailySheet(semesterId: _userProfile!.activeSemesterId!, date: todayDate, subjectStatuses: <String, AttendanceStatus>{});
      _dailySheets[sheetKey] = newSheet;
      HiveService.getDailySheetsBox().put(sheetKey, newSheet);
    }
  }

  // --- Profile Methods ---
  Future<void> saveProfile(String name, String course, String rollNumber) async {
    final userBox = HiveService.getUserProfileBox();
    if (_userProfile == null) {
      _userProfile = UserProfile(name: name, course: course, rollNumber: rollNumber);
      
      // Default semester on profile creation if none exists
      if (_semesters.isNotEmpty) {
        _userProfile!.activeSemesterId = _semesters.first.id;
      }

      // Preserve dark mode
      _userProfile!.isDarkMode = _isDarkMode;
      await userBox.add(_userProfile!);
    } else {
      _userProfile!.name = name;
      _userProfile!.course = course;
      _userProfile!.rollNumber = rollNumber;
      await userBox.putAt(0, _userProfile!);
    }
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    if (_userProfile != null) {
      _userProfile!.isDarkMode = isDark;
      await HiveService.getUserProfileBox().putAt(0, _userProfile!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  Future<void> switchSemester(String semesterId) async {
    if (_userProfile != null) {
      _userProfile!.activeSemesterId = semesterId;
      await HiveService.getUserProfileBox().putAt(0, _userProfile!);
      _ensureTodaySheetExists();
      notifyListeners();
    }
  }

  Future<void> resetAllData() async {
    await HiveService.getUserProfileBox().clear();
    await HiveService.getSubjectsBox().clear();
    await HiveService.getDailySheetsBox().clear();
    await HiveService.getSemestersBox().clear();
    await HiveService.getUniversityClosedBox().clear();
    
    _userProfile = null;
    _subjects.clear();
    _dailySheets.clear();
    _semesters.clear();
    _closedDays.clear();
    
    // We don't call _ensureTodaySheetExists here because profile is null
    notifyListeners();
  }

  // --- Semester Methods ---
  Future<void> addSemester(String name) async {
    final newSemester = Semester(id: const Uuid().v4(), name: name);
    await HiveService.getSemestersBox().put(newSemester.id, newSemester);
    _semesters.add(newSemester);
    
    // If it's the first semester, auto-switch to it
    if (_semesters.length == 1 && _userProfile != null) {
      await switchSemester(newSemester.id);
    }
    
    notifyListeners();
  }

  Future<void> updateSemester(String id, String newName) async {
    final semester = _semesters.firstWhere((s) => s.id == id);
    semester.name = newName;
    await HiveService.getSemestersBox().put(id, semester);
    notifyListeners();
  }

  Future<void> deleteSemester(String id) async {
    await HiveService.getSemestersBox().delete(id);
    _semesters.removeWhere((s) => s.id == id);

    // Cascade delete subjects for this semester
    final subjectsToDelete = _subjects.where((s) => s.semesterId == id).toList();
    for (var sub in subjectsToDelete) {
      await deleteSubject(sub.id);
    }

    // Cascade delete daily sheets for this semester
    final sheetsBox = HiveService.getDailySheetsBox();
    final keysToDelete = _dailySheets.entries.where((e) => e.value.semesterId == id).map((e) => e.key).toList();
    for (var key in keysToDelete) {
      await sheetsBox.delete(key);
      _dailySheets.remove(key);
    }

    if (_userProfile?.activeSemesterId == id) {
      _userProfile!.activeSemesterId = _semesters.isNotEmpty ? _semesters.first.id : null;
      if (_userProfile != null) {
          await HiveService.getUserProfileBox().putAt(0, _userProfile!);
      }
    }
    
    notifyListeners();
  }

  // --- Subject Methods ---
  Future<void> addSubject(String name) async {
    if (_userProfile?.activeSemesterId == null) return;

    final newSubject = Subject(id: const Uuid().v4(), name: name, semesterId: _userProfile!.activeSemesterId!);
    await HiveService.getSubjectsBox().put(newSubject.id, newSubject);
    _subjects.add(newSubject);
    _ensureTodaySheetExists(); // Force update today's sheet
    notifyListeners();
  }

  Future<void> updateSubject(String id, String newName) async {
    final subject = _subjects.firstWhere((s) => s.id == id);
    subject.name = newName;
    await HiveService.getSubjectsBox().put(id, subject);
    notifyListeners();
  }

  Future<void> deleteSubject(String id) async {
    await HiveService.getSubjectsBox().delete(id);
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // --- Attendance Methods ---
  DailySheet getSheetForDate(String date) {
    if (_userProfile?.activeSemesterId == null) {
      return DailySheet(semesterId: '', date: date); // Dummy
    }
    final sheetKey = '${_userProfile!.activeSemesterId}_$date';
    return _dailySheets[sheetKey] ?? DailySheet(semesterId: _userProfile!.activeSemesterId!, date: date);
  }

  Future<void> updateAttendance(String date, String subjectId, AttendanceStatus status) async {
    if (_userProfile?.activeSemesterId == null) return;
    
    final sheetKey = '${_userProfile!.activeSemesterId}_$date';
    DailySheet? sheet = _dailySheets[sheetKey];
    
    if (sheet == null) {
      sheet = DailySheet(semesterId: _userProfile!.activeSemesterId!, date: date, subjectStatuses: <String, AttendanceStatus>{});
      _dailySheets[sheetKey] = sheet; // Add to in-memory map
    }

    if (sheet.isClosed) return; // Cannot modify closed sheet

    sheet.subjectStatuses[subjectId] = status; // Store enum
    await HiveService.getDailySheetsBox().put(sheetKey, sheet);
    notifyListeners();
  }

  Future<void> closeDay(String date, String reason) async {
    if (_userProfile?.activeSemesterId == null) return;
    
    final sheetKey = '${_userProfile!.activeSemesterId}_$date';
    final sheet = _dailySheets[sheetKey];
    if (sheet != null) {
      sheet.isClosed = true;
      sheet.reason = reason;
      await HiveService.getDailySheetsBox().put(sheetKey, sheet);
      notifyListeners();
    }
  }

  Future<void> toggleUniversityClosed(String date, bool isClosed, {String? reason}) async {
    final box = HiveService.getUniversityClosedBox();
    if (isClosed) {
      final newClosedDay = UniversityClosedDay(
        id: const Uuid().v4(), 
        date: date, 
        reason: reason,
      );
      _closedDays[date] = newClosedDay;
      await box.put(date, newClosedDay);
    } else {
      _closedDays.remove(date);
      await box.delete(date);
    }
    notifyListeners();
  }

  // Get stats for a specific subject
  Map<String, dynamic> getSubjectStats(String subjectId) {
    int present = 0;
    int absent = 0;
    int classNotTaken = 0;
    int noClass = 0;

    for (var sheet in dailySheets.values) { // Iterates over ACTIVE SEMESTER daily sheets only
      // Skip if this date is a University Closed day
      if (_closedDays.containsKey(sheet.date)) continue;

      final status = sheet.subjectStatuses[subjectId];
      if (status == AttendanceStatus.present) present++;
      if (status == AttendanceStatus.absent) absent++;
      if (status == AttendanceStatus.classNotTaken) classNotTaken++;
      if (status == AttendanceStatus.noClass) noClass++;
    }

    final totalEffectiveClasses = present + absent;
    final percentage = totalEffectiveClasses > 0 ? (present / totalEffectiveClasses) * 100.0 : 0.0;

    return {
      'present': present,
      'absent': absent,
      'classNotTaken': classNotTaken,
      'noClass': noClass,
      'totalEffective': totalEffectiveClasses,
      'percentage': percentage,
    };
  }

  // Calculate percentage (Only Present/Absent count towards total)
  double getSubjectPercentage(String subjectId) {
    final stats = getSubjectStats(subjectId);
    return stats['percentage'] as double;
  }
}
