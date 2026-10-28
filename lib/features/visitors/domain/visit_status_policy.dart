import 'visitor_status.dart';

class VisitStatusPolicy {
  static bool canCheckIn(VisitorStatus status) {
    return status == VisitorStatus.registered || status == VisitorStatus.checkedOut;
  }

  static bool canCheckOut(VisitorStatus status) {
    return status == VisitorStatus.checkedIn;
  }

  static bool isCompleted(VisitorStatus status) {
    return status == VisitorStatus.checkedOut;
  }

  static VisitorStatus nextStatusOnCheckIn(VisitorStatus current) {
    if (!canCheckIn(current)) {
      throw StateError('Cannot check in visitor with status ${current.label}');
    }
    return VisitorStatus.checkedIn;
  }

  static VisitorStatus nextStatusOnCheckOut(VisitorStatus current) {
    if (!canCheckOut(current)) {
      throw StateError('Cannot check out visitor with status ${current.label}');
    }
    return VisitorStatus.checkedOut;
  }
}
