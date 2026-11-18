import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/provider.dart';
import 'model.dart';
import 'provider.dart';

// TODO-DESIGN: Stitch belum memiliki layar face enrollment/camera. Tampilan ini
// mengikuti design system Executive Deep Glass dan perlu diselaraskan bila
// desain khusus face recognition sudah tersedia.
class FaceConsentView extends ConsumerWidget {
  const FaceConsentView({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faceProvider);
    return _FaceScaffold(
      title: 'Persetujuan Data Biometrik',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.face_retouching_natural_rounded,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Sebelum mendaftarkan wajah',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JAHRIS akan mengambil beberapa foto wajah untuk membuat data referensi di server perusahaan.',
                ),
                SizedBox(height: AppSpacing.md),
                _ConsentPoint(
                  icon: Icons.cloud_outlined,
                  text: 'Keputusan kecocokan wajah dilakukan oleh server, bukan di perangkat.',
                ),
                _ConsentPoint(
                  icon: Icons.delete_sweep_outlined,
                  text: 'Foto sementara dihapus dari cache setelah selesai dikirim.',
                ),
                _ConsentPoint(
                  icon: Icons.lock_outline_rounded,
                  text: 'Data dikirim melalui HTTPS dengan token akun Anda dan tidak disimpan ke galeri.',
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Dengan memilih “Setuju dan lanjut”, Anda menyetujui penggunaan data biometrik untuk verifikasi kehadiran.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Setuju dan lanjut',
            icon: Icons.verified_user_outlined,
            isLoading: state.isProcessing,
            onPressed: () async {
              final saved = await ref
                  .read(faceProvider.notifier)
                  .saveConsent(employeeId, true);
              if (context.mounted && saved) {
                context.go('/face/enroll/$employeeId?self=true');
              }
            },
          ),
          if (state.errorMessage case final message?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: state.isProcessing
                ? null
                : () async {
                    final saved = await ref
                        .read(faceProvider.notifier)
                        .saveConsent(employeeId, false);
                    if (!saved) return;
                    ref.read(authProvider.notifier).resolveFaceEnrollment();
                    if (context.mounted) context.go('/dashboard');
                  },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

class FaceCameraView extends ConsumerWidget {
  const FaceCameraView({required this.args, super.key});

  final FaceFlowArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(faceProvider);
    final controller = ref.read(faceProvider.notifier).cameraController;
    return _FaceCameraLifecycle(
      args: args,
      child: _FaceScaffold(
        title: args.mode == FaceFlowMode.enroll
            ? 'Daftarkan Wajah'
            : 'Verifikasi Wajah',
        child: state.result != null
            ? _FaceResult(args: args, state: state)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _CameraFrame(state: state, controller: controller),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.instruction,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (args.mode == FaceFlowMode.verify) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tidak perlu menekan tombol. Tahan pose sebentar sampai foto terambil otomatis.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else if (state.step != FaceLivenessStep.siap) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Gerakkan kepala perlahan dan tetap di dalam bingkai. Liveness hanya dilakukan satu kali.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _QualityIndicators(state: state),
                  if (args.mode == FaceFlowMode.enroll ||
                      args.mode == FaceFlowMode.verify) ...[
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(
                      value: state.capturedCount / state.requiredCaptures,
                      minHeight: AppSizes.progress,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${state.capturedCount} dari ${state.requiredCaptures} frame terambil otomatis',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (state.errorMessage case final message?) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    if (message.contains('Izin kamera'))
                      TextButton(
                        onPressed: openAppSettings,
                        child: const Text('Buka Pengaturan'),
                      ),
                  ],
                  if (Env.useMock && args.mode == FaceFlowMode.verify) ...[
                    const SizedBox(height: AppSpacing.md),
                    _MockResultSelector(selected: state.mockVerifyMode),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (args.mode == FaceFlowMode.enroll)
                    PrimaryButton(
                      label: 'Ambil Foto',
                      icon: Icons.camera_alt_rounded,
                      isLoading: state.isProcessing,
                      onPressed: !state.isCameraReady || state.isProcessing
                          ? null
                          : () {
                              if (state.isReadyToCapture) {
                                ref
                                    .read(faceProvider.notifier)
                                    .captureAndSubmit();
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(_captureGuidance(state)),
                                  ),
                                );
                            },
                    )
                  else
                    GlassCard(
                      child: Row(
                        children: [
                          if (state.isProcessing)
                            const SizedBox.square(
                              dimension: AppSizes.icon,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSizes.progress / 4,
                              ),
                            )
                          else
                            const Icon(
                              Icons.motion_photos_auto_rounded,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Text(
                              'Pengambilan otomatis aktif. Ikuti arah gerakan di atas.',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

String _captureGuidance(FaceFlowState state) {
  if (!state.singleFace) {
    return state.faceDetected
        ? 'Pastikan hanya satu wajah berada di dalam bingkai.'
        : 'Posisikan wajah di dalam bingkai kamera.';
  }
  if (!state.lightingEnough) {
    return 'Pencahayaan belum cukup. Pindah ke tempat yang lebih terang.';
  }
  if (!state.sharpEnough) {
    return 'Gambar belum tajam. Tahan ponsel dengan stabil.';
  }
  return 'Ikuti instruksi liveness terlebih dahulu: ${state.instruction}.';
}

class _FaceCameraLifecycle extends ConsumerStatefulWidget {
  const _FaceCameraLifecycle({required this.args, required this.child});

  final FaceFlowArgs args;
  final Widget child;

  @override
  ConsumerState<_FaceCameraLifecycle> createState() =>
      _FaceCameraLifecycleState();
}

class _FaceCameraLifecycleState extends ConsumerState<_FaceCameraLifecycle> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(faceProvider.notifier).initialize(widget.args),
    );
  }

  @override
  void dispose() {
    unawaited(ref.read(faceProvider.notifier).disposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _CameraFrame extends StatelessWidget {
  const _CameraFrame({required this.state, required this.controller});

  final FaceFlowState state;
  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    final borderColor = state.singleFace && state.lightingEnough
        ? AppColors.success
        : AppColors.warning;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.darkBackground),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (state.isCameraReady && controller != null)
                CameraPreview(controller!)
              else
                const Center(child: CircularProgressIndicator()),
              CustomPaint(
                painter: _FaceGuidePainter(
                  overlayColor: AppColors.darkBackground.withValues(
                    alpha: 0.58,
                  ),
                  guideColor: borderColor,
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Center(
                  child: StatusChip(
                    label: state.singleFace
                        ? 'Satu wajah terdeteksi'
                        : 'Posisikan satu wajah',
                    color: borderColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityIndicators extends StatelessWidget {
  const _QualityIndicators({required this.state});

  final FaceFlowState state;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      StatusChip(
        label: state.lightingEnough
            ? 'Pencahayaan cukup'
            : 'Pencahayaan kurang',
        color: state.lightingEnough ? AppColors.success : AppColors.warning,
      ),
      StatusChip(
        label: state.sharpEnough ? 'Gambar tajam' : 'Gambar belum tajam',
        color: state.sharpEnough ? AppColors.success : AppColors.warning,
      ),
      StatusChip(
        label: state.step == FaceLivenessStep.siap
            ? 'Liveness lolos'
            : 'Liveness berlangsung',
        color: state.step == FaceLivenessStep.siap
            ? AppColors.success
            : AppColors.info,
      ),
    ],
  );
}

class _FaceResult extends ConsumerWidget {
  const _FaceResult({required this.args, required this.state});

  final FaceFlowArgs args;
  final FaceFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = state.result!;
    final successful = result.matched;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          successful ? Icons.verified_rounded : Icons.face_retouching_off,
          size: 84,
          color: successful ? AppColors.success : AppColors.danger,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          successful ? 'Berhasil' : 'Verifikasi Gagal',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (!successful && args.mode == FaceFlowMode.verify) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Percobaan ${state.verifyAttempts} dari 3',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (successful)
          PrimaryButton(
            label: args.mode == FaceFlowMode.verify
                ? 'Lanjutkan Absensi'
                : 'Selesai',
            icon: Icons.check_rounded,
            onPressed: () {
              if (args.mode == FaceFlowMode.verify) {
                context.pop(result);
              } else if (args.selfEnrollment) {
                ref.read(authProvider.notifier).resolveFaceEnrollment();
                context.go('/dashboard');
              } else {
                context.pop(true);
              }
            },
          )
        else if (!state.attemptsExhausted)
          PrimaryButton(
            label: 'Coba Lagi',
            icon: Icons.refresh_rounded,
            onPressed: ref.read(faceProvider.notifier).retryVerification,
          )
        else ...[
          const GlassCard(
            child: Text(
              'Batas tiga percobaan telah tercapai. Hubungi admin untuk memeriksa atau mendaftarkan ulang data wajah Anda.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Hubungi admin'),
          ),
        ],
      ],
    );
  }
}

class _MockResultSelector extends ConsumerWidget {
  const _MockResultSelector({required this.selected});

  final MockFaceVerifyMode selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode uji mock', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<MockFaceVerifyMode>(
          segments: const [
            ButtonSegment(
              value: MockFaceVerifyMode.sukses,
              label: Text('Sukses'),
            ),
            ButtonSegment(
              value: MockFaceVerifyMode.gagal,
              label: Text('Gagal'),
            ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => ref
              .read(faceProvider.notifier)
              .setMockVerifyMode(selection.first),
        ),
      ],
    ),
  );
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.info),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _FaceScaffold extends StatelessWidget {
  const _FaceScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.darkBackground, AppColors.darkGradientEnd],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.lightBackground, AppColors.lightGradientEnd],
              ),
      ),
      child: SafeArea(child: child),
    ),
  );
}

class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter({
    required this.overlayColor,
    required this.guideColor,
  });

  final Color overlayColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.68,
      height: size.height * 0.58,
    );
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = overlayColor);
    canvas.drawOval(
      oval,
      Paint()
        ..color = guideColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) =>
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.guideColor != guideColor;
}
