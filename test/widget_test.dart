import 'package:flutter_test/flutter_test.dart';
import 'package:one_gate/core/utils/validators.dart';
import 'package:one_gate/features/visitors/domain/visit_status_policy.dart';
import 'package:one_gate/features/visitors/domain/visitor_status.dart';

void main() {
  group('VisitStatusPolicy Tests', () {
    test('Check-in allowed only when status is registered', () {
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.registered), isTrue);
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.checkedIn), isFalse);
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.checkedOut), isFalse);
    });

    test('Check-out allowed only when status is checkedIn', () {
      expect(VisitStatusPolicy.canCheckOut(VisitorStatus.registered), isFalse);
      expect(VisitStatusPolicy.canCheckOut(VisitorStatus.checkedIn), isTrue);
      expect(VisitStatusPolicy.canCheckOut(VisitorStatus.checkedOut), isFalse);
    });

    test('CheckedOut status is terminal', () {
      expect(VisitStatusPolicy.isCompleted(VisitorStatus.checkedOut), isTrue);
      expect(VisitStatusPolicy.isCompleted(VisitorStatus.registered), isFalse);
      expect(VisitStatusPolicy.isCompleted(VisitorStatus.checkedIn), isFalse);
    });
  });

  group('Validators Tests', () {
    test('Mobile number must be exactly 10 digits', () {
      expect(Validators.validateMobile('9876543210'), isNull);
      expect(Validators.validateMobile('123'), isNotNull);
      expect(Validators.validateMobile('987654321012'), isNotNull);
      expect(Validators.validateMobile('abcdefghij'), isNotNull);
    });

    test('Visitor name must not be empty', () {
      expect(Validators.validateName('Rahul'), isNull);
      expect(Validators.validateName(''), isNotNull);
    });
  });
}
