import 'dart:ui';
import 'package:flutter/material.dart';
import 'daily_sheet_tab.dart';
import 'settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DailySheetTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Allows body to go behind the transparent navbar
      body: _tabs[_currentIndex],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            padding: const EdgeInsets.only(top: 8),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: theme.colorScheme.primary.withOpacity(0.2),
              selectedIndex: _currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.class_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  selectedIcon: Icon(Icons.class_, color: theme.colorScheme.primary),
                  label: 'My Classes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  selectedIcon: Icon(Icons.settings, color: theme.colorScheme.primary),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
