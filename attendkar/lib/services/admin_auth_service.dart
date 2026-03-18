// Admin credential constants — kept server-side hidden by not being in public UI
class AdminAuthService {
  static const String _adminEmail = 'adminattendnahikarega@gmail.com';
  static const String _adminPassword = 'mainhoonadmin@#\$321';

  /// Returns true if the provided credentials match the admin account.
  static bool isAdminLogin(String email, String password) {
    return email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword;
  }

  /// The admin email, used for splash screen routing.
  static String get adminEmail => _adminEmail;
}
