/// Centralized API endpoint configurations.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://api.mypgpms.com/api/v1';
  static const String socketBaseUrl = 'https://api.mypgpms.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String getMe = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String verifyPhone = '/auth/verify-phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';

  // Users endpoints
  static const String updateProfile = '/users/profile';

  // Dashboard endpoint
  static const String dashboard = '/dashboard';

  // Payments endpoints
  static const String payments = '/payments';
  static const String paymentsOverview = '/payments/resident/overview';

  // Complaints endpoints
  static const String complaints = '/complaints';
  static const String complaintCategories = '/complaints/categories';

  // Staff endpoints
  static const String staff = '/users/staff';

  // Food Menu endpoint
  static const String foodMenu = '/food-menu';

  // Room Shifts endpoint
  static const String roomShifts = '/rooms/shifts';

  // Rooms endpoint
  static const String rooms = '/rooms';

  // Stays Checkouts endpoint
  static const String staysCheckouts = '/stays/checkouts';

  // Notices / Notifications endpoint
  static const String noticesResident = '/notices/resident';

  // Visitors endpoint
  static const String visitors = '/visitors';
}

