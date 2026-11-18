import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/modules/auth/service.dart';
import 'package:jahris_mobile/modules/employee/model.dart';
import 'package:jahris_mobile/modules/employee/service.dart';

void main() {
  test('akun mock memakai password admin dan mendukung reset manual', () async {
    final employees = MockEmployeeService();
    const auth = MockAuthService();
    const initialPassword = 'Masuk1234';
    const replacementPassword = 'Baru5678';
    const email = 'alur.mock@jahris.id';

    final employee = await employees.create(
      const EmployeeCreateRequest(
        employee: Employee(
          id: '',
          name: 'Karyawan Alur Mock',
          nik: 'MOCK-LOGIN-1',
          email: email,
          department: 'IT',
          branch: 'Batam',
          position: 'QA',
          status: 'Aktif',
        ),
        password: initialPassword,
        mustChangePassword: true,
      ),
    );

    await expectLater(
      auth.login(email: email, password: 'PasswordSalah1'),
      throwsA(isA<StateError>()),
    );
    final firstLogin = await auth.login(
      email: email,
      password: initialPassword,
    );
    expect(firstLogin.user.id, employee.id);
    expect(firstLogin.user.branchName, 'Batam');
    expect(firstLogin.user.mustChangePassword, isTrue);

    await employees.save(
      Employee(
        id: employee.id,
        name: employee.name,
        nik: employee.nik,
        email: employee.email,
        department: employee.department,
        branch: 'Medan',
        position: employee.position,
        status: employee.status,
        role: employee.role,
      ),
    );
    final loginAfterBranchChange = await auth.login(
      email: email,
      password: initialPassword,
    );
    expect(loginAfterBranchChange.user.branchName, 'Medan');

    await employees.resetPassword(
      employee.id,
      const EmployeePasswordReset(
        password: replacementPassword,
        mustChangePassword: false,
      ),
    );
    final secondLogin = await auth.login(
      email: email,
      password: replacementPassword,
    );
    expect(secondLogin.user.mustChangePassword, isFalse);

    await employees.delete(employee.id);
  });
}
