// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get navTask => 'Tasks';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Try Again';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonShowPassword => 'Show password';

  @override
  String get commonHidePassword => 'Hide password';

  @override
  String get languageIndonesian => 'Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePickerTitle => 'Choose Language';

  @override
  String get languagePickerSubtitle => 'Set the app display language.';

  @override
  String get languageIndonesianTitle => 'Bahasa Indonesia';

  @override
  String get languageIndonesianSub => 'Indonesian · app default';

  @override
  String get languageEnglishSub => 'English (US)';

  @override
  String get languagePickerHint =>
      'Translations are rolling out gradually; some pages are still in Indonesian.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'Failed to load profile.';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileEditFromAvatar => 'Edit profile from avatar';

  @override
  String get profileStatLeave => 'Leave Left';

  @override
  String get profileStatPresent => 'Present This Month';

  @override
  String get profileStatOvertime => 'Overtime';

  @override
  String get profileSectionAccount => 'ACCOUNT';

  @override
  String get profileSectionSettings => 'SETTINGS';

  @override
  String get profileSectionOther => 'OTHER';

  @override
  String get profilePersonalData => 'Personal Data';

  @override
  String get profileDocuments => 'My Documents';

  @override
  String profileDocumentsCount(int count) {
    return '$count files';
  }

  @override
  String get profileBankAccount => 'Bank Account';

  @override
  String get profileBankNotSet => 'Not set';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileDarkTheme => 'Dark Theme';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSecurity => 'Security & Password';

  @override
  String get profileHelp => 'Help';

  @override
  String get profileAbout => 'About App';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileLogoutTitle => 'Log out of Jahris?';

  @override
  String get profileLogoutBody => 'Your active session will end.';

  @override
  String get profileFormTitle => 'Edit Profile';

  @override
  String get profileFormName => 'Name';

  @override
  String get profileFormEmail => 'Email';

  @override
  String get profileFormPhone => 'Phone';

  @override
  String get profileFormSave => 'Save Profile';

  @override
  String get passwordFormTitle => 'Change Password';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordConfirm => 'Confirm new password';

  @override
  String get passwordFormSubtitle =>
      'Use a strong password you have not used on other accounts.';

  @override
  String get passwordCurrentHint => 'Enter your current password';

  @override
  String get passwordNewHint => 'At least 6 characters';

  @override
  String get passwordConfirmHint => 'Repeat the new password';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get passwordStrengthLabel => 'Password strength';

  @override
  String get passwordRuleLength => 'At least 6 characters';

  @override
  String get passwordRuleMix => 'Mix of uppercase, numbers, or symbols';

  @override
  String get passwordRuleMatch => 'Passwords match';

  @override
  String get bankFormTitle => 'Bank Account';

  @override
  String get bankFormHint =>
      'This account is used for salary and reimbursement transfers.';

  @override
  String get bankFormBank => 'Bank name';

  @override
  String get bankFormNumber => 'Account number';

  @override
  String get bankFormHolder => 'Account holder name';

  @override
  String get bankFormSave => 'Save Account';

  @override
  String get dashboardShift => 'Morning Shift · 08:15 – 17:15';

  @override
  String get dashboardCheckIn => 'Check In';

  @override
  String get dashboardScanHint => 'Tap to scan your face';

  @override
  String get dashboardLocation => 'Head Office · within radius';

  @override
  String get dashboardIn => 'In';

  @override
  String get dashboardOut => 'Out';

  @override
  String get dashboardTotal => 'Total';

  @override
  String get dashboardLeave => 'Leave';

  @override
  String get dashboardReimburse => 'Reimburse';

  @override
  String get dashboardPettyCash => 'Petty Cash';

  @override
  String get dashboardMore => 'More';

  @override
  String dashboardNextHoliday(String name) {
    return 'Next holiday: $name';
  }

  @override
  String get dashboardMyRequests => 'My Requests';

  @override
  String get dashboardNoRequests => 'No recent requests yet.';

  @override
  String get dashboardSummaryError => 'Summary could not be loaded.';

  @override
  String get serviceAttendanceHistory => 'Attendance History';

  @override
  String get serviceShift => 'Shift Schedule';

  @override
  String get serviceOvertime => 'Overtime';

  @override
  String get servicePayslip => 'Payslip';

  @override
  String get serviceHoliday => 'Holiday Calendar';

  @override
  String get serviceHelp => 'Help';

  @override
  String get servicesTitle => 'All Services';

  @override
  String get servicesSearch => 'Search services...';

  @override
  String get servicesEmpty => 'No services found.';

  @override
  String get loginSupport => 'Customer Service';

  @override
  String get splashPoweredBy => 'Powered by';

  @override
  String get loginToggleTheme => 'Toggle theme';

  @override
  String get loginWelcome => 'Welcome to Jahris';

  @override
  String get loginTagline =>
      'One access for all your work activities.\nCheck in, view schedules, and request leave on the go.';

  @override
  String get loginToggleSheet => 'Open or close the login panel';

  @override
  String get loginEmail => 'Email Address*';

  @override
  String get loginPassword => 'Password*';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get loginConsent =>
      'By continuing, I agree to the processing of my personal data in accordance with the ';

  @override
  String get loginTerms => 'Terms of Service';

  @override
  String get loginAnd => ' and ';

  @override
  String get loginPrivacy => 'JAHRIS Privacy Policy';

  @override
  String get loginSubmit => 'Sign in to Jahris';

  @override
  String loginWhatsappError(String phone) {
    return 'WhatsApp could not be opened. Contact $phone.';
  }

  @override
  String get loginResetSent => 'Password reset instructions have been sent.';

  @override
  String get forcePasswordTitle => 'Change Password';

  @override
  String get forcePasswordHeading => 'Create a new password';

  @override
  String get forcePasswordBody =>
      'Your admin requires you to change your password before continuing.';

  @override
  String get forcePasswordCurrentRequired => 'Current password is required.';

  @override
  String get forcePasswordSave => 'Save New Password';

  @override
  String get logoLabel => 'JAHRIS logo';

  @override
  String get attTitle => 'Attendance';

  @override
  String get attSubtitle => 'Your attendance summary';

  @override
  String get attLoadError => 'Failed to load attendance data.';

  @override
  String get attPickMonth => 'Choose attendance month';

  @override
  String attSummary(String month) {
    return '$month Summary';
  }

  @override
  String get attRecent => 'Recent History';

  @override
  String get attSeeAll => 'See all';

  @override
  String get attEmptyMonth => 'No attendance records this month yet.';

  @override
  String get attHistoryTitle => 'Attendance History';

  @override
  String get attHistoryError => 'Failed to load attendance history.';

  @override
  String get attHistoryEmpty => 'No attendance history yet.';

  @override
  String get attLoadMore => 'Load more';

  @override
  String get attToday => 'Today';

  @override
  String get attIn => 'In';

  @override
  String get attOut => 'Out';

  @override
  String get attDuration => 'Duration';

  @override
  String attShift(String start, String end) {
    return 'Morning Shift · $start – $end';
  }

  @override
  String get attPresent => 'Present';

  @override
  String get attLate => 'Late';

  @override
  String get attLeave => 'Leave';

  @override
  String get attAbsent => 'Absent';

  @override
  String get attRate => 'Attendance rate';

  @override
  String get attNotOut => 'Not checked out';

  @override
  String attHoursMinutes(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String attHoursShort(String h) {
    return '${h}h';
  }

  @override
  String get attStatusAll => 'All';

  @override
  String get attStatusOnTime => 'On Time';

  @override
  String get attStatusLate => 'Late';

  @override
  String get attStatusPermit => 'Permit';

  @override
  String get attStatusAbsent => 'Absent';

  @override
  String get attStatusWorking => 'Working';

  @override
  String get attStatusDone => 'Done';

  @override
  String get attStatusNotIn => 'Not Checked In';

  @override
  String get attLegendOnTime => 'On time';

  @override
  String get attBack => 'Back';

  @override
  String get attHistoryAbsen => 'Attendance History';

  @override
  String get attFilterStatus => 'Filter status';

  @override
  String get attFilterTitle => 'Filter Status';

  @override
  String get attPrevMonth => 'Previous month';

  @override
  String get attNextMonth => 'Next month';

  @override
  String get attAbsenError => 'Failed to load attendance history.';

  @override
  String get attAvgIn => 'Average check-in';

  @override
  String get attTotalHours => 'Total work hours';

  @override
  String get attDaily => 'Daily Details';

  @override
  String attDailyFiltered(String status) {
    return 'Daily Details · $status';
  }

  @override
  String get attAbsenEmpty => 'No attendance records this month yet.';

  @override
  String attNoStatusData(String status) {
    return 'No data with status $status.';
  }

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get taskTitle => 'Tasks';

  @override
  String get taskAdd => 'Add task';

  @override
  String get taskLoadError => 'Failed to load tasks.';

  @override
  String get taskSavedReady => 'New task is ready to save.';

  @override
  String get taskSearch => 'Search tasks';

  @override
  String taskOnDate(String date) {
    return 'Tasks $date';
  }

  @override
  String get taskShowAll => 'Show all';

  @override
  String get taskEmptyFilter => 'No tasks for this filter yet.';

  @override
  String get taskEmptyToday => 'No tasks for today yet.';

  @override
  String taskEmptyDate(String date) {
    return 'No tasks on $date yet.';
  }

  @override
  String get taskProgressToday => 'Today\'s progress';

  @override
  String taskProgressDate(String date) {
    return 'Progress $date';
  }

  @override
  String get taskNone => 'No tasks';

  @override
  String taskProgressCount(int done, int total) {
    return '$done of $total tasks done';
  }

  @override
  String get taskHasPending => ', has unfinished tasks';

  @override
  String get taskNoReminder => ', no task reminders';

  @override
  String taskFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String taskFilterPending(int count) {
    return 'To do ($count)';
  }

  @override
  String taskFilterDone(int count) {
    return 'Done ($count)';
  }

  @override
  String get taskMarkUndone => 'Mark as not done';

  @override
  String get taskMarkDone => 'Mark as done';

  @override
  String get taskClearSearch => 'Clear search';

  @override
  String get taskNotFound => 'No tasks found.';

  @override
  String get taskPickDue => 'Choose task due date';

  @override
  String get taskNew => 'New Task';

  @override
  String get taskFieldTitle => 'Task title';

  @override
  String get taskFieldTitleHint => 'Prepare Q4 presentation';

  @override
  String get taskFieldNote => 'Notes';

  @override
  String get taskFieldNoteHint => 'Add a note (optional)';

  @override
  String get taskDue => 'Due';

  @override
  String get taskDueToday => 'Today';

  @override
  String get taskDueTomorrow => 'Tomorrow';

  @override
  String get taskDueWeek => 'This week';

  @override
  String get taskDuePick => 'Pick';

  @override
  String get taskPriority => 'Priority';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityMedium => 'Medium';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskSave => 'Save Task';

  @override
  String get taskRemind => 'Remind me';

  @override
  String get taskRemindHint => '30 minutes before due';

  @override
  String get taskMarkedDone => 'Task marked as done.';

  @override
  String get taskStatusUpdated => 'Task status updated.';

  @override
  String get taskStatusFailed => 'Failed to update task status. Try again.';

  @override
  String get taskDetail => 'Task Details';

  @override
  String get taskMenu => 'Task menu';

  @override
  String get taskComments => 'Comments';

  @override
  String taskCommentsCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get taskMarkInProgress => 'Mark In Progress';

  @override
  String get taskMarkDoneTitle => 'Mark as Done';

  @override
  String get taskDetailError => 'Failed to load task details.';

  @override
  String taskPriorityLabel(String priority) {
    return '$priority priority';
  }

  @override
  String get taskDescription => 'Description';

  @override
  String get taskSubtasks => 'Subtasks';

  @override
  String taskSubtaskCount(int done, int total) {
    return '$done of $total';
  }

  @override
  String taskAttachments(int count) {
    return '$count attachments';
  }

  @override
  String get taskDoneTitle => 'Task Done';

  @override
  String get taskAssignedBy => 'Assigned by';

  @override
  String get taskStatus => 'Status';

  @override
  String get taskStatusInProgress => 'In Progress';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get taskNoComments => 'No comments yet.';

  @override
  String get taskAddComment => 'Add a comment';
}
