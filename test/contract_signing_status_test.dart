import 'package:flutter_test/flutter_test.dart';
import 'package:zhuxiang_app/features/rental_flow/domain/entities/contract_signing.dart';

void main() {
  test('tenant signature is enough to enter payment before landlord signs', () {
    const status = ContractSigningStatus(
      contractStatus: 'SIGNING',
      currentUserSigned: true,
      lessorSigned: false,
      tenantSigned: true,
      downloadAvailable: false,
    );

    expect(status.isCompleted, isFalse);
    expect(status.readyForPayment, isTrue);
  });

  test('unsigned tenant cannot enter payment', () {
    const status = ContractSigningStatus(
      contractStatus: 'SIGNING',
      currentUserSigned: false,
      lessorSigned: false,
      tenantSigned: false,
      downloadAvailable: false,
    );

    expect(status.readyForPayment, isFalse);
  });
}
