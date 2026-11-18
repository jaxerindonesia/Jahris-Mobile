import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/leave/service.dart';

void main() {
  test('pengajuan cuti mengirim ID jenis cuti dari API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    late FormData submittedForm;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/submission-types') {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': [
                    {'id': 'type-annual', 'name': 'Cuti Tahunan'},
                  ],
                },
              ),
            );
            return;
          }
          if (options.path == '/submissions') {
            submittedForm = options.data as FormData;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {
                  'data': {
                    'id': 'submission-new',
                    'user': {'name': 'Fams'},
                    'submissionType': {'name': 'Cuti Tahunan'},
                    'startDate': '2026-11-10T00:00:00.000',
                    'endDate': '2026-11-11T00:00:00.000',
                    'reason': 'Keperluan keluarga',
                    'status': 'PENDING',
                    'createdAt': '2026-11-02T00:00:00.000',
                  },
                },
              ),
            );
            return;
          }
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );

    await ApiLeaveService(dio, userId: 'fams-id').create(
      type: 'type-annual',
      startDate: DateTime(2026, 11, 10),
      endDate: DateTime(2026, 11, 11),
      reason: 'Keperluan keluarga',
    );

    final fields = {
      for (final field in submittedForm.fields) field.key: field.value,
    };
    expect(fields['userId'], 'fams-id');
    expect(fields['submissionTypeId'], 'type-annual');
    expect(fields['reason'], 'Keperluan keluarga');
  });

  test('pengajuan cuti menolak jenis yang tidak berasal dari API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.jahris.id/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            data: const {'data': <Map<String, dynamic>>[]},
          ),
        ),
      ),
    );

    expect(
      () => ApiLeaveService(dio, userId: 'fams-id').create(
        type: 'Cuti Tahunan',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 11),
        reason: 'Keperluan keluarga',
      ),
      throwsStateError,
    );
  });
}
