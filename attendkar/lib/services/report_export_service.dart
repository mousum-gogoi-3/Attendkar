import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/student_firestore_model.dart';
import '../models/subject_model.dart';

class ReportExportService {
  /// Exports analytics data to an Excel file and shares it.
  static Future<void> exportToExcel({
    required String programName,
    required SubjectModel subject,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<Map<String, dynamic>> analyticsData,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    excel.setDefaultSheet('Sheet1');

    // Row 1: Title
    sheet.cell(CellIndex.indexByString("C1")).value = TextCellValue("ATTENDANCE REPORT");

    // Row 2: Date
    final dateFormat = DateFormat('dd/MM/yy');
    final String startStr = startDate != null ? dateFormat.format(startDate) : "ALL";
    final String endStr = endDate != null ? dateFormat.format(endDate) : "ALL";
    sheet.cell(CellIndex.indexByString("B2")).value = TextCellValue("DATE");
    sheet.cell(CellIndex.indexByString("C2")).value = TextCellValue(startStr);
    sheet.cell(CellIndex.indexByString("D2")).value = TextCellValue("TO");
    sheet.cell(CellIndex.indexByString("E2")).value = TextCellValue(endStr);

    // Row 3: Meta data
    sheet.cell(CellIndex.indexByString("A3")).value = TextCellValue("PROGRAM");
    sheet.cell(CellIndex.indexByString("B3")).value = TextCellValue(programName.toUpperCase());
    sheet.cell(CellIndex.indexByString("C3")).value = TextCellValue("SEMESTER");
    sheet.cell(CellIndex.indexByString("D3")).value = TextCellValue(subject.semester);
    sheet.cell(CellIndex.indexByString("E3")).value = TextCellValue("COURSE ID");
    sheet.cell(CellIndex.indexByString("F3")).value = TextCellValue(subject.courseCode);

    // Row 4: Headers
    final headers = [
      "ROLL NO.",
      "NAME",
      "PRESENT DAYS",
      "ABSENT DAYS",
      "TOTAL DAYS",
      "PERCENTAGE",
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
          .value = TextCellValue(headers[i]);
    }

    // Row 5+: Data
    for (int i = 0; i < analyticsData.length; i++) {
      final data = analyticsData[i];
      final StudentFirestoreModel student = data['student'];
      final int present = data['present'];
      final int absent = data['absent'];
      final int total = data['total'];
      final double percentage = data['percentage'];

      final int rowIndex = i + 4; // Data starts at row 5 (index 4)
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(student.rollNo);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(student.name);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = IntCellValue(present);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = IntCellValue(absent);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = IntCellValue(total);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = IntCellValue(percentage.round()); // Store integer percentage to match formatting
    }

    // Save and Share
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Attendance_Report_${subject.name}.xlsx');
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Attendance Report for ${subject.name}',
      );
    }
  }

  /// Exports analytics data to a PDF file and shares it.
  static Future<void> exportToPdf({
    required String programName,
    required SubjectModel subject,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<Map<String, dynamic>> analyticsData,
  }) async {
    final pdf = pw.Document();
    
    final dateFormat = DateFormat('dd/MM/yy');
    final String startStr = startDate != null ? dateFormat.format(startDate) : "ALL";
    final String endStr = endDate != null ? dateFormat.format(endDate) : "ALL";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text("ATTENDANCE REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("DATE: $startStr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text("TO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text(endStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("PROGRAM: ${programName.toUpperCase()}"),
                pw.Text("SEMESTER: ${subject.semester}"),
                pw.Text("COURSE ID: ${subject.courseCode}"),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              headers: [
                "ROLL NO.",
                "NAME",
                "PRESENT DAYS",
                "ABSENT DAYS",
                "TOTAL DAYS",
                "PERCENTAGE"
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              data: analyticsData.map((data) {
                final StudentFirestoreModel student = data['student'];
                final int present = data['present'];
                final int absent = data['absent'];
                final int total = data['total'];
                final double percentage = data['percentage'];

                return [
                  student.rollNo,
                  student.name,
                  present.toString(),
                  absent.toString(),
                  total.toString(),
                  "${percentage.round()}", // store as int string matching formatting
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    // Save and Share
    final fileBytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Attendance_Report_${subject.name}.pdf');
    await file.writeAsBytes(fileBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Attendance Report for ${subject.name}',
    );
  }
}
