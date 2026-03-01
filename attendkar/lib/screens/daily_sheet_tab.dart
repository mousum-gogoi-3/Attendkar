import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../models/subject.dart';
import '../models/daily_sheet.dart';
import '../models/attendance_status.dart';
import '../widgets/custom_card.dart';

class DailySheetTab extends StatefulWidget {
  const DailySheetTab({super.key});

  @override
  State<DailySheetTab> createState() => _DailySheetTabState();
}

class _DailySheetTabState extends State<DailySheetTab> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _universityClosedReasonController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedDateStr;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _universityClosedReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AttendanceProvider>(context);
    final displayDate = DateFormat('EEEE, d MMM').format(_selectedDate);
    
    final sheet = provider.getSheetForDate(_selectedDateStr);
    bool isPastDay = _selectedDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    bool isClosed = (sheet?.isClosed ?? false) || isPastDay;
    
    final universityClosedDay = provider.closedDays[_selectedDateStr];
    bool isUniversityClosed = universityClosedDay != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(displayDate),
        actions: [
          if (isClosed)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day Closed',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: provider.subjects.isEmpty
        ? _buildEmptyState()
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              if (!isUniversityClosed)
                _buildMarkUniversityClosedButton(theme, provider, isPastDay),
              const SizedBox(height: 16),
              if (!isUniversityClosed)
                ...provider.subjects.map((subject) {
                final currentStatus = sheet?.subjectStatuses[subject.id];
                return CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  _buildStatusChip(
                                    provider, 
                                    _selectedDateStr, 
                                    subject.id, 
                                    AttendanceStatus.present, 
                                    currentStatus, 
                                    isClosed,
                                    theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    provider, 
                                    _selectedDateStr, 
                                    subject.id, 
                                    AttendanceStatus.absent, 
                                    currentStatus, 
                                    isClosed,
                                    theme.colorScheme.error,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  _buildStatusChip(
                                    provider, 
                                    _selectedDateStr, 
                                    subject.id, 
                                    AttendanceStatus.classNotTaken, 
                                    currentStatus, 
                                    isClosed,
                                    Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(
                                    provider, 
                                    _selectedDateStr, 
                                    subject.id, 
                                    AttendanceStatus.noClass, 
                                    currentStatus, 
                                    isClosed,
                                    Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (!isUniversityClosed) ...[
                const SizedBox(height: 24),
                _buildEndOfDayControl(theme, provider, sheet, _selectedDateStr),
              ],
              if (isUniversityClosed)
                _buildUniversityIsClosedState(theme, provider, universityClosedDay?.reason, isPastDay),
              const SizedBox(height: 32),
            ],
          ),
    );
  }

  Widget _buildMarkUniversityClosedButton(ThemeData theme, AttendanceProvider provider, bool isPastDay) {
    if (isPastDay) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          _showUniversityClosedDialog(context, provider);
        },
        icon: Icon(Icons.domain_disabled, color: theme.colorScheme.primary),
        label: Text(
          'Mark University Closed',
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        style: TextButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showUniversityClosedDialog(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark University Closed?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will disable attendance tracking for today.'),
            const SizedBox(height: 16),
            TextField(
              controller: _universityClosedReasonController,
              decoration: InputDecoration(
                hintText: 'Optional Reason (e.g. Holiday, Strike)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
            ElevatedButton(
              onPressed: () {
                provider.toggleUniversityClosed(
                  _selectedDateStr, 
                  true, 
                  reason: _universityClosedReasonController.text.trim()
                );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
              child: const Text('Yes, Close University'),
            ),
        ],
      ),
    );
  }

  Widget _buildUniversityIsClosedState(ThemeData theme, AttendanceProvider provider, String? existingReason, bool isPastDay) {
    return Center(
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.domain_disabled, 
                  size: 64, 
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'University Closed Today',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (existingReason != null && existingReason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Reason: $existingReason',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    AttendanceProvider provider, 
    String dateStr, 
    String subjectId, 
    AttendanceStatus statusEnum, 
    AttendanceStatus? currentStatus, 
    bool isClosed,
    Color activeColor,
  ) {
    // Current status is stored as Enum
    bool isSelected = currentStatus == statusEnum;

    return ChoiceChip(
      label: Text(statusEnum.displayName),
      selected: isSelected,
      onSelected: isClosed ? null : (selected) {
        HapticFeedback.lightImpact();
        if (selected) {
          provider.updateAttendance(dateStr, subjectId, statusEnum);
        } else {
          provider.updateAttendance(dateStr, subjectId, AttendanceStatus.unselected); // Unselect
        }
      },
      selectedColor: activeColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? activeColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildEndOfDayControl(ThemeData theme, AttendanceProvider provider, sheet, String todayStr) {
    if (sheet.isClosed) {
      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'End of Day Closed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            if (sheet.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Reason: ${sheet.reason}',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ]
          ],
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'End of Day Control',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Closing the day locks all subjects from further changes.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Optional Reason (e.g. Early leave)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showCloseConfirmation(context, provider, todayStr);
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('Close Today\'s Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context, AttendanceProvider provider, String date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Day?'),
        content: const Text('Are you sure? You cannot edit attendance logs for today after closing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.closeDay(date, _reasonController.text.trim());
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Colors.white),
            child: const Text('Yes, Close Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_outlined, 
              size: 64, 
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready for a new day!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Head over to Settings to add your subjects\nand start tracking your attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}
