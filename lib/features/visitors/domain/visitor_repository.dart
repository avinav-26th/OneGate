import 'visitor.dart';
import 'visitor_status.dart';

// repository contract for visitor registry operations
abstract class VisitorRepository {
  Future<List<Visitor>> getVisitors({bool forceRefresh = false});
  Future<List<Visitor>> getRecycleBinVisitors();
  Future<Visitor> getVisitorById(String id);
  Future<Visitor> createVisitor(Visitor visitor);
  Future<Visitor> updateVisitor(Visitor visitor);
  Future<void> softDeleteVisitor(String id);
  Future<void> deleteVisitor(String id);
  Future<void> restoreVisitor(String id);
  Future<void> hardDeleteVisitor(String id);
  Future<void> emptyRecycleBin();
  Future<Visitor> updateStatus(String id, VisitorStatus newStatus, DateTime timestamp);
  Future<void> autoPurgeExpiredRecycleBin([Duration retention = const Duration(days: 30)]);
  Future<void> syncPendingMutations();
}
