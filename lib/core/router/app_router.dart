import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/attendance/view.dart';
import '../../modules/auth/model.dart';
import '../../modules/auth/provider.dart';
import '../../modules/auth/view.dart';
import '../../modules/bantuan/view.dart';
import '../../modules/branch/view.dart';
import '../../modules/dashboard/view.dart';
import '../../modules/employee/view.dart';
import '../../modules/face/model.dart';
import '../../modules/face/view.dart';
import '../../modules/holiday/view.dart';
import '../../modules/leave/view.dart';
import '../../modules/notification/view.dart';
import '../../modules/overtime/view.dart';
import '../../modules/payroll/view.dart';
import '../../modules/performance/view.dart';
import '../../modules/pettycash/view.dart';
import '../../modules/profile/view.dart';
import '../../modules/reimburse/view.dart';
import '../../modules/task/view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.listen<AuthState>(authProvider, (_, _) => refresh.notify());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final onSplash = state.matchedLocation == '/splash';
      if (!ref.read(splashDoneProvider)) return onSplash ? null : '/splash';
      if (onSplash) return '/login';
      final auth = ref.read(authProvider);
      final onLogin = state.matchedLocation == '/login';
      final onRequiredPassword =
          state.matchedLocation == '/change-password-required';
      final onFaceOnboarding =
          state.matchedLocation.startsWith('/face/consent') ||
          state.matchedLocation.startsWith('/face/enroll');
      if (auth.status == AuthStatus.checking) return null;
      if (auth.status != AuthStatus.authenticated && !onLogin) return '/login';
      if (auth.status == AuthStatus.authenticated &&
          auth.requiresPasswordChange &&
          !onRequiredPassword) {
        return '/change-password-required';
      }
      if (auth.status == AuthStatus.authenticated &&
          !auth.requiresPasswordChange &&
          onRequiredPassword) {
        return auth.requiresFaceEnrollment
            ? '/face/consent/${auth.user!.id}'
            : '/dashboard';
      }
      if (auth.status == AuthStatus.authenticated &&
          auth.requiresFaceEnrollment &&
          !onFaceOnboarding) {
        return '/face/consent/${auth.user!.id}';
      }
      if (auth.status == AuthStatus.authenticated && onLogin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
      GoRoute(path: '/splash', builder: (_, _) => const SplashView()),
      GoRoute(path: '/login', builder: (_, _) => const LoginView()),
      GoRoute(
        path: '/change-password-required',
        builder: (_, _) => const RequiredPasswordChangeView(),
      ),
      GoRoute(
        path: '/face/consent/:employeeId',
        builder: (_, state) =>
            FaceConsentView(employeeId: state.pathParameters['employeeId']!),
      ),
      GoRoute(
        path: '/face/enroll/:employeeId',
        builder: (_, state) => FaceCameraView(
          args: FaceFlowArgs(
            employeeId: state.pathParameters['employeeId']!,
            mode: FaceFlowMode.enroll,
            selfEnrollment: state.uri.queryParameters['self'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/face/verify',
        builder: (_, state) =>
            FaceCameraView(args: state.extra! as FaceFlowArgs),
      ),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardView()),
      GoRoute(path: '/holiday', builder: (_, _) => const HolidayView()),
      GoRoute(
        path: '/leave',
        builder: (_, state) => LeaveView(
          showApprovals: state.uri.queryParameters['approval'] == 'true',
        ),
      ),
      GoRoute(
        path: '/leave/detail/:id',
        builder: (_, state) => LeaveDetailView(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/attendance', builder: (_, _) => const AttendanceView()),
      GoRoute(
        path: '/attendance/history',
        builder: (_, _) => const AttendanceHistoryView(),
      ),
      GoRoute(path: '/task', builder: (_, _) => const TaskView()),
      GoRoute(
        path: '/task/detail/:id',
        builder: (_, state) => TaskDetailView(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/reimburse', builder: (_, _) => const ReimburseView()),
      GoRoute(
        path: '/reimburse/detail/:id',
        builder: (_, state) =>
            ReimburseDetailView(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/employees', builder: (_, _) => const EmployeeView()),
      GoRoute(
        path: '/employees/:id',
        builder: (_, state) =>
            EmployeeDetailView(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/branches', builder: (_, _) => const BranchView()),
      GoRoute(
        path: '/shift-schedule',
        builder: (_, _) => const ShiftScheduleView(),
      ),
      GoRoute(path: '/payroll', builder: (_, _) => const PayrollView()),
      GoRoute(
        path: '/payroll/manage',
        builder: (_, _) => const PayrollManagementView(),
      ),
      GoRoute(path: '/overtimes', builder: (_, _) => const OvertimeView()),
      GoRoute(path: '/pettycash', builder: (_, _) => const PettyCashView()),
      GoRoute(path: '/bantuan', builder: (_, _) => const HelpCenterView()),
      GoRoute(
        path: '/performances',
        builder: (_, _) => const PerformanceView(),
      ),
      GoRoute(
        path: '/payroll/slip/:id',
        builder: (_, state) =>
            PayrollSlipDetailView(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationView(),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileView()),
      GoRoute(
        path: '/attendance/config',
        builder: (_, _) => const AttendanceConfigView(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
