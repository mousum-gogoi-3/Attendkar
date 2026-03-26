import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/subject_model.dart';
import '../../services/admin_firestore_service.dart';

class AdminUploadStudentsScreen extends StatefulWidget {
  final SubjectModel subject;

  const AdminUploadStudentsScreen({super.key, required this.subject});

  @override
  State<AdminUploadStudentsScreen> createState() =>
      _AdminUploadStudentsScreenState();
}

class _AdminUploadStudentsScreenState
    extends State<AdminUploadStudentsScreen> {
  // ─── Manual entry ─────────────────────────────────────────────────────────
  final _manualFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  bool _manualLoading = false;

  // ─── CSV ──────────────────────────────────────────────────────────────────
  List<Map<String, String>> _parsedStudents = [];
  String? _csvError;
  bool _csvLoading = false;
  bool _csvUploading = false;
  String? _csvFileName;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _deptCtrl.dispose();
    _sectionCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  // ─── Manual save ─────────────────────────────────────────────────────────
  Future<void> _saveManual() async {
    if (!_manualFormKey.currentState!.validate()) return;
    setState(() => _manualLoading = true);
    await AdminFirestoreService.createStudent(
      name: _nameCtrl.text.trim(),
      rollNo: _rollCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
      section: _sectionCtrl.text.trim(),
      semester: _semesterCtrl.text.trim(),
      subjectId: widget.subject.subjectId,
    );
    setState(() => _manualLoading = false);
    _nameCtrl.clear();
    _rollCtrl.clear();
    _deptCtrl.clear();
    _sectionCtrl.clear();
    _semesterCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Student added successfully!',
            style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF0CA678),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── CSV pick ─────────────────────────────────────────────────────────────
  Future<void> _pickCsv() async {
    setState(() {
      _csvError = null;
      _parsedStudents = [];
      _csvFileName = null;
      _csvLoading = true;
    });

    try {
      // 1. Request permissions
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          setState(() {
            _csvLoading = false;
            _csvError = 'Storage permission permanently denied. Please enable it in Settings.';
          });
          return;
        }
      }

      // 2. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // custom with csv sometimes fails on some Android devices
        withData: false, // Save memory, use path instead
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _csvLoading = false);
        return;
      }
      final file = result.files.first;
      
      // Enforce CSV extension manually since FileType.any is used
      if (!file.name.toLowerCase().endsWith('.csv')) {
        setState(() {
          _csvLoading = false;
          _csvError = 'Please select a valid .csv file.';
        });
        return;
      }

      _csvFileName = file.name;

      // 3. Read file
      String csvString;
      if (file.path != null) {
        csvString = await File(file.path!).readAsString();
      } else if (file.bytes != null) {
        csvString = String.fromCharCodes(file.bytes!);
      } else {
        setState(() {
          _csvLoading = false;
          _csvError = 'Could not read file path.';
        });
        return;
      }

      // 4. Parse CSV
      final rows = const CsvToListConverter(eol: '\n').convert(csvString.replaceAll('\r\n', '\n'));
      if (rows.length < 2) {
        setState(() {
          _csvLoading = false;
          _csvError = 'CSV file is empty or has no data rows.';
        });
        return;
      }

      // 5. Detect header row
      final header =
          rows[0].map((e) => e.toString().trim().toLowerCase()).toList();
      final nameIdx = _findCol(header, ['name', 'student name', 'full name']);
      final deptIdx = _findCol(header, ['department', 'dept']);
      final rollIdx = _findCol(header, ['roll_no', 'rollno', 'roll no', 'roll']);
      final sectionIdx = _findCol(header, ['section', 'sec']);
      final semesterIdx = _findCol(header, ['semester', 'sem']);

      if (nameIdx == -1 || rollIdx == -1) {
        setState(() {
          _csvLoading = false;
          _csvError =
              'CSV must have "name" and "roll_no" columns. Found: ${header.join(", ")}';
        });
        return;
      }

      final students = <Map<String, String>>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
          continue;
        }
        students.add({
          'name': nameIdx < row.length ? row[nameIdx].toString().trim() : '',
          'department':
              deptIdx != -1 && deptIdx < row.length
                  ? row[deptIdx].toString().trim()
                  : '',
          'rollNo': rollIdx < row.length ? row[rollIdx].toString().trim() : '',
          'section':
              sectionIdx != -1 && sectionIdx < row.length
                  ? row[sectionIdx].toString().trim()
                  : '',
          'semester':
              semesterIdx != -1 && semesterIdx < row.length
                  ? row[semesterIdx].toString().trim()
                  : '',
        });
      }

      setState(() {
        _parsedStudents = students;
        _csvLoading = false;
      });
    } catch (e) {
      setState(() {
        _csvLoading = false;
        _csvError = 'Error parsing CSV: $e';
      });
    }
  }

  int _findCol(List<String> header, List<String> candidates) {
    for (final c in candidates) {
      final idx = header.indexOf(c);
      if (idx != -1) return idx;
    }
    return -1;
  }

  Future<void> _uploadCsv() async {
    if (_parsedStudents.isEmpty) return;
    setState(() => _csvUploading = true);
    final count = await AdminFirestoreService.uploadStudents(
      _parsedStudents,
      widget.subject.subjectId,
    );
    setState(() {
      _csvUploading = false;
      _parsedStudents = [];
      _csvFileName = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count students uploaded successfully!',
            style: GoogleFonts.outfit()),
        backgroundColor: const Color(0xFF0CA678),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload Students',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(widget.subject.name,
                style:
                    GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor:
            isDark ? const Color(0xFF163B30) : const Color(0xFF0CA678),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Manual Entry Section ────────────────────────────────────
            _SectionHeader(
              icon: Icons.edit_note_rounded,
              title: 'Option 1: Manual Entry',
              color: const Color(0xFF3B5BDB),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.12),
                ),
              ),
              child: Form(
                key: _manualFormKey,
                child: Column(
                  children: [
                    _buildField(_nameCtrl, 'Full Name', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildField(_rollCtrl, 'Roll Number', Icons.numbers_outlined),
                    const SizedBox(height: 12),
                    _buildField(_deptCtrl, 'Department', Icons.domain_outlined),
                    const SizedBox(height: 12),
                    _buildField(_sectionCtrl, 'Section', Icons.group_outlined),
                    const SizedBox(height: 12),
                    _buildField(_semesterCtrl, 'Semester', Icons.school_outlined),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _manualLoading ? null : _saveManual,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B5BDB),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _manualLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_rounded),
                        label: Text(_manualLoading ? 'Saving...' : 'Add Student',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── CSV Upload Section ───────────────────────────────────────
            _SectionHeader(
              icon: Icons.upload_file_rounded,
              title: 'Option 2: CSV Upload',
              color: const Color(0xFF0CA678),
            ),
            const SizedBox(height: 12),

            // Format hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0CA678).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF0CA678).withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF0CA678), size: 16),
                    const SizedBox(width: 8),
                    Text('Expected CSV format:',
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF0CA678),
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      'name,department,roll_no,section,semester\n'
                      'Rahul Das,CSE,22CSE101,A,3\n'
                      'Priya Sharma,CSE,22CSE102,A,3\n'
                      'Aman Verma,ME,22ME101,B,5',
                      style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Pick button
            OutlinedButton.icon(
              onPressed: _csvLoading ? null : _pickCsv,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0CA678),
                side: const BorderSide(color: Color(0xFF0CA678)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _csvLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFF0CA678), strokeWidth: 2))
                  : const Icon(Icons.folder_open_rounded),
              label: Text(_csvFileName != null
                  ? _csvFileName!
                  : 'Select CSV File',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),

            if (_csvError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_csvError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],

            // Preview table
            if (_parsedStudents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.preview_rounded,
                          color: Color(0xFF0CA678), size: 18),
                      const SizedBox(width: 8),
                      Text('Preview: ${_parsedStudents.length} students',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0CA678))),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        itemCount: _parsedStudents.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _parsedStudents[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      const Color(0xFF0CA678).withValues(alpha: 0.1),
                                  child: Text('${i + 1}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: const Color(0xFF0CA678))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                     '${s['name']} · ${s['rollNo']} · Sec ${s['section']}${(s['semester'] ?? '').isNotEmpty ? ' · Sem ${s['semester']}' : ''}',
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _csvUploading ? null : _uploadCsv,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0CA678),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _csvUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                            _csvUploading
                                ? 'Uploading...'
                                : 'Upload ${_parsedStudents.length} Students',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF3B5BDB), width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF121224)
            : Colors.grey.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? '$label is required' : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}
