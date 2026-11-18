/// Seluruh path REST JAHRIS yang dipakai aplikasi mobile.
///
/// Base URL tetap berada di `core/config/env.dart`. File ini hanya menyimpan
/// path agar service tiap modul fokus pada payload dan parsing respons.
abstract final class ApiEndpoints {
  // Authentication
  static const authLogin = '/auth/login';
  static const authSession = '/auth/session';
  static const authLogout = '/auth/logout';
  static const authCsrf = '/auth/csrf';
  static const authCredentials = '/auth/callback/credentials';
  static const authSignOut = '/auth/signout';
  static const authForgotPassword = '/auth/forgot-password';
  static const authChangePassword = '/auth/change_password';
  static const authSwitchTenant = '/auth/switch-tenant';

  // Dashboard and master data
  static const dashboard = '/dashboard';
  static const users = '/users';
  static String user(String id) => '$users/$id';
  static const userImport = '/users/import';
  static const branches = '/branches';
  static String branch(String id) => '$branches/$id';
  static const departments = '/departments';
  static const roles = '/roles';

  // Attendance and face recognition
  static const attendances = '/attendances';
  static String userAttendances(String userId) => '$attendances/user/$userId';
  static const attendanceCheckIn = '/attendances/check-in';
  static const attendanceCheckOut = '/attendances/check-out';
  static const attendanceConfig = '/attendance-config';
  static const faceVerify = '/face-recognition/verify';

  // Submissions and reimbursements
  static const submissions = '/submissions';
  static String submission(String id) => '$submissions/$id';
  static const submissionTypes = '/submission-types';
  static const leaveConfigs = '/leave-configs';
  static const reimbursements = '/reimbursements';
  static String reimbursement(String id) => '$reimbursements/$id';

  // Operational modules
  static const overtimes = '/overtimes';
  static String overtime(String id) => '$overtimes/$id';
  static const overtimeRequest = '/overtimes/request';
  static const overtimeCheckIn = '/overtimes/check-in';
  static const overtimeCheckOut = '/overtimes/check-out';
  static const overtimeConfig = '/overtime-config';
  static const pettyCash = '/pettycash';
  static String pettyCashDetail(String id) => '$pettyCash/$id';
  static String pettyCashUsage(String id) => '$pettyCash/$id/usage';
  static const performances = '/performances';
  static String performance(String id) => '$performances/$id';
  static const performancePreview = '/performances/preview';

  // Task management
  static const taskDepartments = '/task-managements/departments';
  static const taskLists = '/task-managements/lists';
  static const taskCategories = '/task-managements/categories';
  static const taskDoneMovePermissions =
      '/task-managements/done-move-permissions';
  static const tasks = '/task-managements/tasks';
  static String task(String id) => '$tasks/$id';

  // Payroll
  static const payrolls = '/payrolls';
  static String payroll(String id) => '$payrolls/$id';
  static const payrollSummary = '/payrolls/summary';
  static const payrollCalculationSummary = '/payrolls/calculation-summary';
  static const payrollComponentConfig = '/payroll-component-config';
  static String payrollComponent(String id) => '$payrollComponentConfig/$id';

  // Notification endpoints belum terverifikasi dari web.
  static const notifications = '/notifications';
  static String notificationRead(String id) => '$notifications/$id/read';
  static const notificationsReadAll = '/notifications/read-all';
  static const devices = '/devices';
}
