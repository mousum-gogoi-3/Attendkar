# Attendkar
Attendkar is a local-first, scalable, lightweight attendance management app designed for educational institutions. It is built to work efficiently on low-end devices, ensuring data protection and offline-first capabilities. The app currently focuses on faculty and student panels, with a role-based architecture to allow future expansion to include an admin panel or backend server integration. The app is designed to be update-safe, meaning new features can be added without breaking existing functionality.

Core Objectives

Simplify attendance management for faculty.

Enable students to check their attendance in real-time.

Maintain a local-first architecture to work offline and store data securely on the device.

Support future upgrades like notifications, admin panel, cloud sync, or university closure alerts.

Keep the app lightweight to run smoothly on low-end devices.

User Roles and Panels
1. Student Panel

Login: Students log in using their Gmail account and password.

Welcome Screen: Displays a welcome message: “Welcome to Attendkar – Select your role,” then redirects to login.

Features:

View attendance history for each subject.

Display attendance percentage in a clean dashboard.

Optionally, show class schedule or upcoming holidays/university closure (future upgrade).

Local storage ensures attendance data is available even offline.

2. Faculty Panel

Login: Faculty log in using their Gmail account and password.

Features:

Mark attendance for each class or session.

Edit attendance records for corrections.

View overall attendance statistics for classes.

Optionally, export attendance as a CSV or PDF (future upgrade).

Add university closure or leave with reason (future upgrade).

Offline capability: marks attendance locally and syncs when online.

3. Admin Panel (Future Upgrade)

Not implemented yet, but the architecture allows smooth integration.

Functions could include:

Adding/removing users (students/faculty).

Managing subjects and schedules.

Reviewing attendance analytics.

Features and Functionalities

Local-first storage:

Attendance is saved locally on the device to ensure accessibility without internet.

Designed for data protection: sensitive user data (Gmail, password) is stored securely.

Scalable Architecture:

The app uses role-based design, making it easy to add more user roles (admin, parent, guest).

Future backend integration will be smooth without changing the core app.

Lightweight UI/UX:

Minimalist interface to reduce memory consumption.

Clear navigation: Welcome → Role selection → Login → Dashboard.

Offline & Online Mode:

Works fully offline; updates sync when internet is available.

Ensures reliability in low connectivity environments.

Security & Privacy:

Passwords are securely stored (hashed/encrypted locally).

No unnecessary cloud exposure unless future upgrades integrate backend.

Future-proof Features (Planned):

University closure option with optional reason.

Notifications for students and faculty about attendance or important updates.

Export & report generation (PDF, CSV).

Admin panel & backend sync.

Technical Notes for Developers

Front-end: Designed for minimal resource usage; can be built in Flutter, React Native, or similar cross-platform frameworks.

Local Storage: SQLite, Hive, or SharedPreferences can be used.

Future Backend Integration: API endpoints for syncing attendance, managing users, and sending notifications.

Role-based Logic: Keep roles abstracted so adding new roles won’t require rewriting the app.

UI Restrictions: Do not change the current UI flow for the student panel in upgrades; only add screens or enhancements.

Suggested UI Flow

Welcome Screen: “Welcome to Attendkar – Select your role” → Buttons: Student / Faculty.

Login Screen: Gmail + Password → Validation → Redirect to Dashboard.

Student Dashboard: Attendance overview per subject, total percentage, optional schedule view.

Faculty Dashboard: Mark attendance, edit attendance, view class stats.

Future Popups: Notifications, university closure alerts, optional messages.
