import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/visit_status_policy.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_repository.dart';
import '../../domain/visitor_status.dart';
import 'visitor_list_controller.dart';
import 'visitor_providers.dart';

class VisitorDetailsNotifier extends StateNotifier<AsyncValue<Visitor?>> {
  final VisitorRepository _repository;
  final Ref _ref;

  VisitorDetailsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<Visitor?> loadVisitor(String id) async {
    state = const AsyncValue.loading();
    try {
      final visitor = await _repository.getVisitorById(id);
      state = AsyncValue.data(visitor);
      return visitor;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void setVisitor(Visitor visitor) {
    state = AsyncValue.data(visitor);
  }

  Future<bool> checkIn(String id) async {
    final current = state.value;
    if (current == null || !VisitStatusPolicy.canCheckIn(current.status)) {
      return false;
    }
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateStatus(
        id,
        VisitorStatus.checkedIn,
        DateTime.now(),
      );
      state = AsyncValue.data(updated);
      _ref.read(visitorListNotifierProvider.notifier).upsertVisitor(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> checkOut(String id) async {
    final current = state.value;
    if (current == null || !VisitStatusPolicy.canCheckOut(current.status)) {
      return false;
    }
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateStatus(
        id,
        VisitorStatus.checkedOut,
        DateTime.now(),
      );
      state = AsyncValue.data(updated);
      _ref.read(visitorListNotifierProvider.notifier).upsertVisitor(updated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteVisitor(id);
      state = const AsyncValue.data(null);
      _ref.read(visitorListNotifierProvider.notifier).deleteVisitor(id);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final visitorDetailsNotifierProvider =
    StateNotifierProvider<VisitorDetailsNotifier, AsyncValue<Visitor?>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorDetailsNotifier(repository, ref);
});
