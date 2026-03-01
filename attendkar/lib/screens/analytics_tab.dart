import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../widgets/custom_card.dart';
import '../models/attendance_status.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: theme.primaryColor,
              tabs: const [
                Tab(text: 'Subjects'),
                Tab(text: 'History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSubjectsView(context, provider, theme),
                  _buildHistoryView(context, provider, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsView(BuildContext context, AttendanceProvider provider, ThemeData theme) {
    if (provider.subjects.isEmpty) {
      return const Center(child: Text('No subjects added.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: provider.subjects.length,
      itemBuilder: (context, index) {
        final subject = provider.subjects[index];
        final stats = provider.getSubjectStats(subject.id);
        final percentage = stats['percentage'] as double;
        final totalEffective = stats['totalEffective'] as int;

        Color percentColor = theme.colorScheme.secondary;
        if (percentage < 75 && totalEffective > 0) {
          percentColor = theme.colorScheme.error;
        }

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 35,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                value: totalEffective == 0 ? 0 : stats['present']!.toDouble(),
                                color: percentColor,
                                radius: 12,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: totalEffective == 0 ? 1 : (totalEffective - stats['present']!).toDouble(),
                                color: theme.colorScheme.onSurface.withOpacity(0.1),
                                radius: 12,
                                showTitle: false,
                              ),
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 800),
                          swapAnimationCurve: Curves.easeOutQuint,
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: percentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatBadge(label: 'Present', count: stats['present']!, color: theme.colorScheme.primary),
                            _StatBadge(label: 'Absent', count: stats['absent']!, color: theme.colorScheme.error),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatBadge(label: 'Not Taken', count: stats['classNotTaken']!, color: Colors.grey),
                            _StatBadge(label: 'No Class', count: stats['noClass']!, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryView(BuildContext context, AttendanceProvider provider, ThemeData theme) {
    final sheets = provider.dailySheets.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // descending

    if (sheets.isEmpty) {
      return const Center(child: Text('No attendance history.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: sheets.length,
      itemBuilder: (context, index) {
        final sheet = sheets[index];
        DateTime parsedDate = DateTime.parse(sheet.date);
        String displayDate = DateFormat('EEEE, d MMM yyyy').format(parsedDate);

        final bool isUniversityClosed = provider.closedDays.containsKey(sheet.date);
        final universityClosedDay = provider.closedDays[sheet.date];

        Widget subtitleWidget;
        if (isUniversityClosed) {
          subtitleWidget = Row(
            children: [
              Icon(Icons.domain_disabled, size: 14, color: theme.colorScheme.error),
              const SizedBox(width: 4),
              Text('University Closed', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ],
          );
        } else if (sheet.isClosed) {
          subtitleWidget = Row(
            children: [
              Icon(Icons.lock, size: 14, color: theme.colorScheme.error),
              const SizedBox(width: 4),
              Text('Closed', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
            ],
          );
        } else {
          subtitleWidget = const Text('Open', style: TextStyle(color: Colors.green, fontSize: 12));
        }

        return CustomCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            title: Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: subtitleWidget,
            children: [
              if (isUniversityClosed && universityClosedDay?.reason != null && universityClosedDay!.reason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${universityClosedDay.reason}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (sheet.isClosed && sheet.reason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${sheet.reason}',
                          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isUniversityClosed) ...[
                const Divider(),
                ...provider.subjects.map((sub) {
                  final status = sheet.subjectStatuses[sub.id] ?? AttendanceStatus.unselected;
                  return ListTile(
                    dense: true,
                    title: Text(sub.name),
                    trailing: Text(
                      status.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == AttendanceStatus.present 
                            ? theme.colorScheme.primary 
                            : status == AttendanceStatus.absent 
                                ? theme.colorScheme.error 
                                : Colors.grey,
                      ),
                    ),
                  );
                }),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text('No classes scheduled today', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}
