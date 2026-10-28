import 'package:flutter_test/flutter_test.dart';
import 'package:one_gate/core/data/data_orchestrator.dart';
import 'package:one_gate/core/utils/validators.dart';
import 'package:one_gate/features/visitors/domain/visit_session.dart';
import 'package:one_gate/features/visitors/domain/visit_status_policy.dart';
import 'package:one_gate/features/visitors/domain/visitor.dart';
import 'package:one_gate/features/visitors/domain/visitor_status.dart';

void main() {
  group('VisitStatusPolicy Tests', () {
    test('Check-in allowed when status is registered or checkedOut for re-visiting', () {
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.registered), isTrue);
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.checkedOut), isTrue);
      expect(VisitStatusPolicy.canCheckIn(VisitorStatus.checkedIn), isFalse);
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

  group('Visitor Entity & Tier Data Tests', () {
    test('Soft delete flag and deletedAt can be set', () {
      final now = DateTime.now();
      final visitor = Visitor(
        id: 'TEST1',
        name: 'Test Visitor',
        mobile: '9876543210',
        visitorType: 'Customer',
        project: 'Project A',
        purpose: 'Meeting',
        status: VisitorStatus.registered,
        createdAt: now,
        isDeleted: true,
        deletedAt: now,
      );
      expect(visitor.isDeleted, isTrue);
      expect(visitor.deletedAt, equals(now));

      final restored = visitor.copyWith(isDeleted: false, clearDeletedAt: true);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
    });

    test('ComputedTierMetrics aggregates active and bin visitors correctly', () {
      final now = DateTime.now();
      final v1 = Visitor(
        id: '1',
        name: 'V1',
        mobile: '9876543210',
        visitorType: 'Customer',
        project: 'Project A',
        purpose: 'Site Visit',
        status: VisitorStatus.checkedIn,
        createdAt: now,
        checkInTime: now,
      );
      final v2 = Visitor(
        id: '2',
        name: 'V2',
        mobile: '9876543211',
        visitorType: 'Vendor',
        project: 'Project B',
        purpose: 'Delivery',
        status: VisitorStatus.checkedOut,
        createdAt: now,
        checkOutTime: now,
      );
      final vBin = Visitor(
        id: '3',
        name: 'V3',
        mobile: '9876543212',
        visitorType: 'Other',
        project: 'Project C',
        purpose: 'Other',
        status: VisitorStatus.registered,
        createdAt: now,
        isDeleted: true,
        deletedAt: now,
      );

      final metrics = ComputedTierMetrics.fromVisitors([v1, v2], [vBin]);
      expect(metrics.totalCount, equals(2));
      expect(metrics.totalToday, equals(2));
      expect(metrics.currentlyIn, equals(1));
      expect(metrics.checkedOutToday, equals(1));
      expect(metrics.recycleBinCount, equals(1));
    });

    test('VisitSession duration and completion tracking', () {
      final start = DateTime(2026, 10, 27, 10, 0);
      final end = DateTime(2026, 10, 27, 10, 45);
      final session = VisitSession(
        id: 'SES-1',
        checkInTime: start,
        checkOutTime: end,
        purpose: 'Site Inspection',
      );
      expect(session.isCompleted, isTrue);
      expect(session.durationText, equals('45 mins'));

      final activeSession = VisitSession(
        id: 'SES-2',
        checkInTime: DateTime.now(),
      );
      expect(activeSession.isCompleted, isFalse);
    });
  });
}
