import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_gate/core/constants/app_errors.dart';
import 'package:one_gate/core/data/data_orchestrator.dart';
import 'package:one_gate/core/errors/failure.dart';
import 'package:one_gate/core/utils/validators.dart';
import 'package:one_gate/core/widgets/shimmer_loading.dart';
import 'package:one_gate/features/visitors/data/visitor_api_service.dart';
import 'package:one_gate/features/visitors/domain/visit_session.dart';
import 'package:one_gate/features/visitors/domain/visit_status_policy.dart';
import 'package:one_gate/features/visitors/domain/visitor.dart';
import 'package:one_gate/features/visitors/domain/visitor_status.dart';

class _MockDioAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockDioAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

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

  group('AppErrors Tests', () {
    test('AppErrors constants are non-empty and well-defined', () {
      expect(AppErrors.networkGeneral.isNotEmpty, isTrue);
      expect(AppErrors.visitorNotFound.isNotEmpty, isTrue);
      expect(AppErrors.nameRequired.isNotEmpty, isTrue);
      expect(AppErrors.mobileRequired.isNotEmpty, isTrue);
      expect(AppErrors.registrationFailed.isNotEmpty, isTrue);
      expect(AppErrors.cameraPermissionRequired.isNotEmpty, isTrue);
      expect(AppErrors.cameraPermissionRequired, contains('Camera permission'));
    });

    test('Validators use AppErrors constants', () {
      expect(Validators.validateName(''), equals(AppErrors.nameRequired));
      expect(Validators.validateName('a'), equals(AppErrors.nameMinLength));
      expect(Validators.validateMobile(''), equals(AppErrors.mobileRequired));
      expect(Validators.validateMobile('123'), equals(AppErrors.mobileExactDigits));
      expect(Validators.validateEmail('invalid'), equals(AppErrors.emailInvalid));
    });
  });

  group('ShimmerLoading Widgets Tests', () {
    testWidgets('TodayMetricsShimmer renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TodayMetricsShimmer(),
          ),
        ),
      );
      expect(find.byType(TodayMetricsShimmer), findsOneWidget);
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('RecentVisitorListShimmer renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecentVisitorListShimmer(count: 2),
          ),
        ),
      );
      expect(find.byType(RecentVisitorListShimmer), findsOneWidget);
      expect(find.byType(RecentVisitorTileShimmer), findsNWidgets(2));
    });

    testWidgets('VisitorListShimmer renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VisitorListShimmer(count: 3),
          ),
        ),
      );
      expect(find.byType(VisitorListShimmer), findsOneWidget);
    });
  });

  group('VisitorApiService (Dio REST Client) Tests', () {
    late Dio dio;
    late VisitorApiService apiService;
    late RequestOptions lastOptions;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://test.mockapi.io/api/v1'));
    });

    test('getVisitors() issues GET /visitors and parses response array', () async {
      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        final jsonResponse = json.encode([
          {
            'id': '1',
            'name': 'Rahul Sharma',
            'mobile': '9876543210',
            'status': 'Registered',
          }
        ]);
        return ResponseBody.fromString(
          jsonResponse,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      final result = await apiService.getVisitors();

      expect(lastOptions.method, equals('GET'));
      expect(lastOptions.path, contains('/visitors'));
      expect(result.length, equals(1));
      expect(result.first['name'], equals('Rahul Sharma'));
    });

    test('getVisitor(id) issues GET /visitors/:id and parses single record', () async {
      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        final jsonResponse = json.encode({
          'id': 'VIS001',
          'name': 'Rahul Sharma',
          'status': 'Registered',
        });
        return ResponseBody.fromString(
          jsonResponse,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      final result = await apiService.getVisitor('VIS001');

      expect(lastOptions.method, equals('GET'));
      expect(lastOptions.path, contains('/visitors/VIS001'));
      expect(result['id'], equals('VIS001'));
      expect(result['name'], equals('Rahul Sharma'));
    });

    test('getVisitor(id) throws Failure with 404 when not found', () async {
      dio.httpClientAdapter = _MockDioAdapter((options) async {
        return ResponseBody.fromString(
          json.encode({'message': 'Not found'}),
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      expect(
        () => apiService.getVisitor('999'),
        throwsA(isA<Failure>().having((f) => f.statusCode, 'statusCode', 404)),
      );
    });

    test('createVisitor() issues POST /visitors with request body', () async {
      final payload = {
        'name': 'Sneha Reddy',
        'mobile': '9876543210',
        'status': 'Registered',
      };

      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        return ResponseBody.fromString(
          json.encode({'id': '10', ...payload}),
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      final created = await apiService.createVisitor(payload);

      expect(lastOptions.method, equals('POST'));
      expect(lastOptions.data, equals(payload));
      expect(created['id'], equals('10'));
      expect(created['name'], equals('Sneha Reddy'));
    });

    test('updateVisitor() issues PUT /visitors/:id with payload', () async {
      final updateData = {
        'name': 'Sneha Updated',
        'project': 'Project B',
      };

      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        return ResponseBody.fromString(
          json.encode({'id': '10', ...updateData}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      final updated = await apiService.updateVisitor('10', updateData);

      expect(lastOptions.method, equals('PUT'));
      expect(lastOptions.path, contains('/visitors/10'));
      expect(lastOptions.data, equals(updateData));
      expect(updated['name'], equals('Sneha Updated'));
    });

    test('patchVisitor() issues PATCH /visitors/:id with status change', () async {
      final patchData = {
        'status': 'Checked In',
        'check_in_time': '2026-10-29T10:00:00.000Z',
      };

      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        return ResponseBody.fromString(
          json.encode({'id': '10', 'name': 'Sneha', ...patchData}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      final patched = await apiService.patchVisitor('10', patchData);

      expect(lastOptions.method, equals('PATCH'));
      expect(lastOptions.path, contains('/visitors/10'));
      expect(lastOptions.data, equals(patchData));
      expect(patched['status'], equals('Checked In'));
    });

    test('deleteVisitor() issues DELETE /visitors/:id and completes successfully', () async {
      dio.httpClientAdapter = _MockDioAdapter((options) async {
        lastOptions = options;
        return ResponseBody.fromString(
          json.encode({'id': '10'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      await apiService.deleteVisitor('10');

      expect(lastOptions.method, equals('DELETE'));
      expect(lastOptions.path, contains('/visitors/10'));
    });

    test('handles Dio connectionTimeout gracefully as Failure(408)', () async {
      dio.httpClientAdapter = _MockDioAdapter((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      apiService = VisitorApiService(dio: dio, baseUrl: 'https://test.mockapi.io/api/v1');
      expect(
        () => apiService.getVisitors(),
        throwsA(isA<Failure>().having((f) => f.statusCode, 'statusCode', 408)),
      );
    });
  });
}
