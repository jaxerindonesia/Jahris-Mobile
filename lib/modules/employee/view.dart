import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/list_states.dart';
import '../../core/widgets/module_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secure_screen.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/provider.dart';
import '../branch/provider.dart';
import '../face/model.dart';
import '../face/provider.dart';
import 'model.dart';
import 'provider.dart';

class EmployeeView extends ConsumerWidget {
  const EmployeeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(employeeProvider);
    return ModuleScaffold(
      title: 'Karyawan',
      subtitle: 'Kelola data karyawan dan departemen.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: value.when(
        loading: () => const ListLoading(),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Data karyawan gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(employeeProvider),
        ),
        data: (data) => _EmployeeContent(data: data),
      ),
    );
  }

  Future<void> _openForm(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _EmployeeForm(parentContext: context),
  );
}

class _EmployeeContent extends ConsumerWidget {
  const _EmployeeContent({required this.data});
  final EmployeeState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(employeeProvider.notifier);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: [
          TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Cari nama atau NIK',
            ),
            onSubmitted: controller.search,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: data.departmentFilter,
                  decoration: const InputDecoration(labelText: 'Departemen'),
                  items: ['Semua', ...data.departments.map((item) => item.name)]
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.filter(department: value);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: data.statusFilter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['Semua', 'Aktif', 'Tidak Aktif']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.filter(status: value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openActions(context, ref, data),
            icon: const Icon(Icons.more_horiz_rounded),
            label: const Text('Aksi'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (data.message case final message?) ...[
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (data.items.isEmpty)
            const GlassCard(
              child: Center(child: Text('Karyawan tidak ditemukan.')),
            )
          else ...[
            for (final item in data.items) ...[
              _EmployeeCard(item: item),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              'Menampilkan ${data.items.length} dari ${data.total} data',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (data.hasMore)
              TextButton(
                onPressed: controller.loadMore,
                child: const Text('Muat lainnya'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    EmployeeState state,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.account_tree_rounded),
            title: const Text('Kelola Departemen'),
            onTap: () {
              Navigator.pop(sheetContext);
              _openDepartments(context, ref, state.departments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_rounded),
            title: const Text('Download Semua PDF'),
            onTap: () {
              Navigator.pop(sheetContext);
              ref.read(employeeProvider.notifier).export('pdf');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_view_rounded),
            title: const Text('Export Excel'),
            onTap: () {
              Navigator.pop(sheetContext);
              ref.read(employeeProvider.notifier).export('excel');
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_rounded),
            title: const Text('Import'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final file = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['xlsx', 'xls', 'csv'],
              );
              if (file?.path case final path?) {
                await ref.read(employeeProvider.notifier).importFile(path);
              }
            },
          ),
        ],
      ),
    ),
  );

  Future<void> _openDepartments(
    BuildContext context,
    WidgetRef ref,
    List<Department> departments,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Kelola Departemen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in departments)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_tree_rounded),
              title: Text(item.name),
              trailing: Text('${item.employeeCount} karyawan'),
            ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tambah departemen',
              suffixIcon: Icon(Icons.add_rounded),
            ),
            onSubmitted: (value) =>
                ref.read(employeeProvider.notifier).addDepartment(value),
          ),
        ],
      ),
    ),
  );
}

class _EmployeeCard extends ConsumerWidget {
  const _EmployeeCard({required this.item});
  final Employee item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final face = ref.watch(faceStatusProvider(item.id));
    return GlassCard(
      onTap: () => context.push('/employees/${item.id}'),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.16),
            child: Text(item.name.characters.first),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                Text(item.nik, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.department} • ${item.branch}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(label: item.status),
              const SizedBox(height: AppSpacing.xs),
              face.when(
                loading: () => const SizedBox.square(
                  dimension: AppSizes.iconSmall,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const StatusChip(
                  label: 'Status wajah tidak tersedia',
                  color: AppColors.warning,
                ),
                data: (value) => StatusChip(
                  label: value.status.label,
                  color: value.status == FaceEnrollmentStatus.sudah
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmployeeDetailView extends ConsumerWidget {
  const EmployeeDetailView({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(employeeDetailProvider(id));
    final face = ref.watch(faceStatusProvider(id));
    final isAdmin =
        ref.watch(authProvider).user?.role.toLowerCase().contains('admin') ??
        false;
    return ModuleScaffold(
      title: 'Detail Karyawan',
      body: value.when(
        loading: () => const ListLoading(itemCount: 2),
        error: (error, _) => ListError(
          message: networkErrorMessage(
            error,
            fallback: 'Detail karyawan gagal dimuat.',
          ),
          onRetry: () => ref.invalidate(employeeDetailProvider(id)),
        ),
        data: (item) => ListView(
          children: [
            GlassCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                    child: Text(
                      item.name.characters.first,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  StatusChip(label: item.status),
                  const SizedBox(height: AppSpacing.lg),
                  _Detail(label: 'NIK', value: item.nik),
                  _Detail(label: 'Email', value: item.email),
                  _Detail(label: 'Posisi', value: item.position),
                  _Detail(label: 'Departemen', value: item.department),
                  _Detail(label: 'Cabang', value: item.branch),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Data Wajah',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      face.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const StatusChip(
                          label: 'Tidak tersedia',
                          color: AppColors.warning,
                        ),
                        data: (status) => StatusChip(
                          label: status.status.label,
                          color: status.status == FaceEnrollmentStatus.sudah
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.push<bool>('/face/enroll/$id');
                        ref.invalidate(faceStatusProvider(id));
                      },
                      icon: const Icon(Icons.face_rounded),
                      label: const Text('Daftar ulang wajah'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _confirmFaceDelete(context, ref),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Hapus data wajah'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _ResetPasswordDialog(employeeId: id),
                      ),
                      icon: const Icon(Icons.password_rounded),
                      label: const Text('Reset Password'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => _EmployeeForm(current: item),
                    ),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Ubah'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus karyawan?'),
        content: const Text('Data karyawan akan dihapus dari tenant.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(employeeProvider.notifier).delete(id);
      if (context.mounted) context.pop();
    }
  }

  Future<void> _confirmFaceDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus data wajah?'),
        content: const Text(
          'Karyawan tidak dapat melakukan absensi sampai wajah didaftarkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus data wajah'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(faceProvider.notifier).deleteEnrollment(id);
      ref.invalidate(faceStatusProvider(id));
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _EmployeeForm extends ConsumerStatefulWidget {
  const _EmployeeForm({this.current, this.parentContext});
  final Employee? current;
  final BuildContext? parentContext;

  @override
  ConsumerState<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<_EmployeeForm> {
  final _dataFormKey = GlobalKey<FormState>();
  final _accessFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nikController;
  late final TextEditingController _emailController;
  late final TextEditingController _positionController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmationController;
  late String _department;
  late String _branch;
  late String _status;
  late String _role;
  var _step = 0;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _mustChangePassword = true;

  Employee? get current => widget.current;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: current?.name ?? '');
    _nikController = TextEditingController(text: current?.nik ?? '');
    _emailController = TextEditingController(text: current?.email ?? '');
    _positionController = TextEditingController(text: current?.position ?? '');
    _passwordController = TextEditingController()..addListener(_refresh);
    _confirmationController = TextEditingController()..addListener(_refresh);
    _emailController.addListener(_refresh);
    _department = current?.department ?? 'HR';
    _branch = current?.branch ?? '';
    _status = current?.status ?? 'Aktif';
    _role = current?.role ?? 'Karyawan';
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _accessValid =>
      Validators.email(_emailController.text) == null &&
      Validators.employeePassword(_passwordController.text) == null &&
      Validators.passwordConfirmation(
            _confirmationController.text,
            _passwordController.text,
          ) ==
          null;

  Employee _employee({String? id}) => Employee(
    id: id ?? current?.id ?? '',
    name: _nameController.text.trim(),
    nik: _nikController.text.trim(),
    email: _emailController.text.trim(),
    department: _department,
    branch: _branch,
    position: _positionController.text.trim(),
    status: _status,
    role: _role,
  );

  Future<void> _saveEdit() async {
    FocusScope.of(context).unfocus();
    if (!(_dataFormKey.currentState?.validate() ?? false) || _isSaving) return;
    setState(() => _isSaving = true);
    final saved = await ref.read(employeeProvider.notifier).save(_employee());
    if (!mounted) return;
    if (saved == null) {
      setState(() => _isSaving = false);
      _showFailure('Data karyawan gagal disimpan.');
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _createAndEnroll() async {
    FocusScope.of(context).unfocus();
    if (!(_accessFormKey.currentState?.validate() ?? false) ||
        !_accessValid ||
        _isSaving) {
      return;
    }
    setState(() {
      _step = 2;
      _isSaving = true;
    });
    var oneTimePassword = _passwordController.text;
    final employeeController = ref.read(employeeProvider.notifier);
    final saved = await employeeController.create(
      EmployeeCreateRequest(
        employee: _employee(),
        password: oneTimePassword,
        mustChangePassword: _mustChangePassword,
      ),
    );
    _passwordController.clear();
    _confirmationController.clear();
    if (!mounted) {
      oneTimePassword = '';
      return;
    }
    if (saved == null) {
      oneTimePassword = '';
      setState(() {
        _step = 1;
        _isSaving = false;
      });
      _showFailure('Akun karyawan gagal dibuat.');
      return;
    }

    final navigationContext = widget.parentContext;
    Navigator.pop(context);
    if (navigationContext == null || !navigationContext.mounted) {
      await employeeController.delete(saved.id);
      oneTimePassword = '';
      return;
    }
    final enrolled = await navigationContext.push<bool>(
      '/face/enroll/${saved.id}',
    );
    if (enrolled != true) {
      await employeeController.delete(saved.id);
      if (navigationContext.mounted) {
        ScaffoldMessenger.of(navigationContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Pendaftaran dibatalkan karena wajah belum didaftarkan.',
            ),
          ),
        );
      }
      oneTimePassword = '';
      return;
    }
    if (navigationContext.mounted) {
      await _showCreatedAccount(
        navigationContext,
        email: saved.email,
        password: oneTimePassword,
      );
    }
    oneTimePassword = '';
  }

  void _showFailure(String fallback) {
    final message = ref.read(employeeProvider).value?.message;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message ?? fallback)));
  }

  @override
  Widget build(BuildContext context) {
    final departments =
        ref
            .watch(employeeProvider)
            .value
            ?.departments
            .map((item) => item.name)
            .toList() ??
        ['HR'];
    final branches =
        ref
            .watch(branchOptionsProvider)
            .value
            ?.map((item) => item.name)
            .toList() ??
        <String>[];
    if (!departments.contains(_department)) _department = departments.first;
    if (branches.isNotEmpty && !branches.contains(_branch)) {
      _branch = branches.first;
    }
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: current == null
          ? _buildWizard(context, departments, branches)
          : _buildEditForm(context, departments, branches),
    );
    return current == null ? SecureScreen(child: content) : content;
  }

  Widget _buildWizard(
    BuildContext context,
    List<String> departments,
    List<String> branches,
  ) {
    return ListView(
      shrinkWrap: true,
      children: [
        Text(
          'Tambah Karyawan',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _WizardSteps(current: _step),
        const SizedBox(height: AppSpacing.lg),
        if (_step == 0) _buildEmployeeData(departments, branches),
        if (_step == 1) _buildLoginAccess(),
        if (_step == 2)
          const GlassCard(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('Menyiapkan pendaftaran wajah...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmployeeData(List<String> departments, List<String> branches) {
    return Form(
      key: _dataFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nikController,
            decoration: const InputDecoration(labelText: 'NIK'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'NIK wajib diisi.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _departmentField(departments),
          const SizedBox(height: AppSpacing.md),
          _branchField(branches),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(labelText: 'Posisi'),
          ),
          const SizedBox(height: AppSpacing.md),
          _statusField(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Lanjut',
            onPressed: () {
              if (_dataFormKey.currentState?.validate() ?? false) {
                setState(() => _step = 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginAccess() {
    final strength = EmployeePasswordStrength.evaluate(
      _passwordController.text,
    );
    final roles =
        ref
            .watch(employeeRolesProvider)
            .value
            ?.map((item) => item.name)
            .where((name) => name.isNotEmpty && name != '-')
            .toList() ??
        const ['Karyawan', 'Atasan', 'Manajer'];
    if (roles.isNotEmpty && !roles.contains(_role)) _role = roles.first;
    return Form(
      key: _accessFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Akses Login', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: roles
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => _role = value ?? _role,
          ),
          const SizedBox(height: AppSpacing.md),
          _passwordField(
            controller: _passwordController,
            label: 'Password',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: Validators.employeePassword,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PasswordStrengthIndicator(strength: strength),
          const SizedBox(height: AppSpacing.md),
          _passwordField(
            controller: _confirmationController,
            label: 'Konfirmasi Password',
            obscure: _obscureConfirmation,
            onToggle: () =>
                setState(() => _obscureConfirmation = !_obscureConfirmation),
            validator: (value) => Validators.passwordConfirmation(
              value,
              _passwordController.text,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _mustChangePassword,
            onChanged: (value) => setState(() => _mustChangePassword = value),
            title: const Text('Wajib ganti password saat login pertama'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => setState(() => _step = 0),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Lanjut',
                  icon: Icons.face_retouching_natural_rounded,
                  isLoading: _isSaving,
                  onPressed: _accessValid && !_isSaving
                      ? _createAndEnroll
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    List<String> departments,
    List<String> branches,
  ) {
    return Form(
      key: _dataFormKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Ubah Karyawan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _nikController,
            decoration: const InputDecoration(labelText: 'NIK'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'NIK wajib diisi.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: Validators.email,
          ),
          const SizedBox(height: AppSpacing.md),
          _departmentField(departments),
          const SizedBox(height: AppSpacing.md),
          _branchField(branches),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(labelText: 'Posisi'),
          ),
          const SizedBox(height: AppSpacing.md),
          _statusField(),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Simpan',
            icon: Icons.save_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _saveEdit,
          ),
        ],
      ),
    );
  }

  Widget _departmentField(List<String> departments) =>
      DropdownButtonFormField<String>(
        initialValue: _department,
        decoration: const InputDecoration(labelText: 'Departemen'),
        items: departments
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => _department = value ?? _department,
      );

  Widget _branchField(List<String> branches) => DropdownButtonFormField<String>(
    initialValue: branches.contains(_branch) ? _branch : null,
    decoration: const InputDecoration(labelText: 'Cabang'),
    items: branches
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) => _branch = value ?? _branch,
    validator: (value) => branches.isEmpty || value == null
        ? 'Belum ada cabang aktif yang dapat dipilih.'
        : null,
  );

  Widget _statusField() => DropdownButtonFormField<String>(
    initialValue: _status,
    decoration: const InputDecoration(labelText: 'Status'),
    items: const ['Aktif', 'Tidak Aktif']
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) => _status = value ?? _status,
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    autocorrect: false,
    enableSuggestions: false,
    enableIMEPersonalizedLearning: false,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}

class _WizardSteps extends StatelessWidget {
  const _WizardSteps({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, label) in [
        'Data',
        'Akses Login',
        'Daftar Wajah',
      ].indexed) ...[
        Expanded(
          child: StatusChip(
            label: '${index + 1}. $label',
            color: index <= current ? AppColors.primary : AppColors.darkMuted,
          ),
        ),
        if (index < 2) const SizedBox(width: AppSpacing.xs),
      ],
    ],
  );
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});
  final EmployeePasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      EmployeePasswordStrength.lemah => AppColors.danger,
      EmployeePasswordStrength.sedang => AppColors.warning,
      EmployeePasswordStrength.kuat => AppColors.success,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength.progress,
          color: color,
          minHeight: AppSizes.progress,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Kekuatan password: ${strength.label}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

Future<void> _showCreatedAccount(
  BuildContext context, {
  required String email,
  required String password,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => SecureScreen(
    child: AlertDialog(
      title: const Text('Akun Karyawan Dibuat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Password hanya ditampilkan sekali.'),
          const SizedBox(height: AppSpacing.md),
          SelectableText('Email: $email'),
          const SizedBox(height: AppSpacing.sm),
          SelectableText('Password: $password'),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: 'Email: $email\nPassword: $password'),
            );
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Akun berhasil disalin.')),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Salin'),
        ),
        TextButton.icon(
          onPressed: () => SharePlus.instance.share(
            ShareParams(
              text: 'Akun JAHRIS\nEmail: $email\nPassword: $password',
            ),
          ),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Bagikan'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Selesai'),
        ),
      ],
    ),
  ),
);

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.employeeId});
  final String employeeId;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _mustChangePassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _password.clear();
    _confirmation.clear();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SecureScreen(
    child: AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResetPasswordField(
                controller: _password,
                label: 'Password baru',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: Validators.employeePassword,
              ),
              const SizedBox(height: AppSpacing.md),
              _ResetPasswordField(
                controller: _confirmation,
                label: 'Konfirmasi password baru',
                obscure: _obscureConfirmation,
                onToggle: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                validator: (value) =>
                    Validators.passwordConfirmation(value, _password.text),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _mustChangePassword,
                onChanged: (value) =>
                    setState(() => _mustChangePassword = value),
                title: const Text('Wajib ganti password saat login'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Menyimpan...' : 'Reset Password'),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final password = _password.text;
    final success = await ref
        .read(employeeProvider.notifier)
        .resetPassword(
          widget.employeeId,
          EmployeePasswordReset(
            password: password,
            mustChangePassword: _mustChangePassword,
          ),
        );
    _password.clear();
    _confirmation.clear();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = false);
    final message = ref.read(employeeProvider).value?.message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Password gagal direset.')),
    );
  }
}

class _ResetPasswordField extends StatelessWidget {
  const _ResetPasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscure,
    autocorrect: false,
    enableSuggestions: false,
    enableIMEPersonalizedLearning: false,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        onPressed: onToggle,
        tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
        icon: Icon(
          obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
