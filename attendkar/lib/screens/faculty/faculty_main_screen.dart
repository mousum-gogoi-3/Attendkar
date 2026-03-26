import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/subject_model.dart';
import '../../models/faculty_model.dart';
import 'class_dashboard_screen.dart';
import 'tabs/faculty_profile_tab.dart';
import 'tabs/faculty_reports_tab.dart';

class FacultyMainScreen extends StatefulWidget {
  const FacultyMainScreen({super.key});

  @override
  State<FacultyMainScreen> createState() => _FacultyMainScreenState();
}

class _FacultyMainScreenState extends State<FacultyMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _FacultyHomeTab(),
    FacultyReportsTab(),
    FacultyProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _FacultyHomeTab extends StatefulWidget {
  const _FacultyHomeTab();

  @override
  State<_FacultyHomeTab> createState() => _FacultyHomeTabState();
}

class _FacultyHomeTabState extends State<_FacultyHomeTab> {
  List<SubjectModel> _assignedClasses = [];
  FacultyModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuthService.getLoggedFacultyUid();
    if (uid != null) {
      final profile = await FirestoreService.getFacultyProfile(uid);
      final classes = await FirestoreService.getAssignedSubjects(uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _assignedClasses = classes;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final facultyName = _profile?.name ?? 'Faculty';
    final firstName = facultyName.split(' ').first;
    final currentDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return CustomScrollView(
      slivers: [
        // Clean Minimalist Header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24, right: 24, bottom: 24,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDate,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, $firstName',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.admin_panel_settings_rounded, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                
                if (_profile != null && !_profile!.isVerified) ...[
                   const SizedBox(height: 24),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.error.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.info_outline_rounded, color: theme.colorScheme.error, size: 20),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Text(
                             'Account pending verification by admin.',
                             style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 13),
                           ),
                         ),
                       ],
                     ),
                   ).animate().fadeIn().slideY(begin: 0.1),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Content Area
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (_assignedClasses.isEmpty && (_profile?.isVerified ?? false))
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder_shared_outlined, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 16),
                  Text('No Classes Assigned', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'The administrator has not assigned you\nto any classes yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
          )
        else if (_assignedClasses.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cls = _assignedClasses[index];
                  // Assign a color based on index for the subtle left border accent
                  final accentColors = [
                    const Color(0xFF4F46E5), // Indigo
                    const Color(0xFF2563EB), // Blue
                    const Color(0xFF0EA5E9), // Sky
                    const Color(0xFF10B981), // Emerald
                    const Color(0xFF8B5CF6), // Violet
                  ];
                  final accentColor = accentColors[index % accentColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDashboardScreen(subjectModel: cls),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Clean Left border indicator
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                cls.name,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.business_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Department ID: ${cls.departmentId}',
                                              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        if (cls.courseCode.isNotEmpty || cls.semester.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                Icon(Icons.label_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  [
                                                    if (cls.courseCode.isNotEmpty) 'ID: ${cls.courseCode}',
                                                    if (cls.semester.isNotEmpty) 'Sem: ${cls.semester}'
                                                  ].join(' • '),
                                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms).slideX(begin: 0.05),
                  );
                },
                childCount: _assignedClasses.length,
              ),
            ),
          )
      ],
    );
  }
}
