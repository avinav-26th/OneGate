import 'visitor.dart';
import 'visitor_status.dart';

abstract class VisitorRepository {
  Future<List<Visitor>> getVisitors();
  Future<Visitor> getVisitorById(String id);
  Future<Visitor> createVisitor(Visitor visitor);
  Future<Visitor> updateVisitor(Visitor visitor);
  Future<void> deleteVisitor(String id);
  Future<Visitor> updateStatus(String id, VisitorStatus newStatus, DateTime timestamp);
}
