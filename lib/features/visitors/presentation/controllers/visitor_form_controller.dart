import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_repository.dart';
import '../../domain/visitor_status.dart';
import 'visitor_list_controller.dart';
import 'visitor_providers.dart';

class VisitorFormNotifier extends StateNotifier<AsyncValue<Visitor?>> {
  final VisitorRepository _repository;
  final Ref _ref;

  VisitorFormNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<Visitor?> registerVisitor({
    required String name,
    required String mobile,
    String? email,
    required String visitorType,
    required String project,
    required String purpose,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newVisitor = Visitor(
        id: '',
        name: name.trim(),
        mobile: mobile.trim(),
        email: email != null && email.trim().isNotEmpty ? email.trim() : null,
        visitorType: visitorType,
        project: project,
        purpose: purpose.trim(),
        status: VisitorStatus.registered,
        createdAt: DateTime.now(),
      );

      final created = await _repository.createVisitor(newVisitor);
      state = AsyncValue.data(created);
      _ref.read(visitorListNotifierProvider.notifier).upsertVisitor(created);
      return created;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Visitor?> updateVisitor({
    required Visitor existing,
    required String name,
    required String mobile,
    String? email,
    required String visitorType,
    required String project,
    required String purpose,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedVisitor = existing.copyWith(
        name: name.trim(),
        mobile: mobile.trim(),
        email: email != null && email.trim().isNotEmpty ? email.trim() : null,
        visitorType: visitorType,
        project: project,
        purpose: purpose.trim(),
      );

      final updated = await _repository.updateVisitor(updatedVisitor);
      state = AsyncValue.data(updated);
      _ref.read(visitorListNotifierProvider.notifier).upsertVisitor(updated);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final visitorFormNotifierProvider =
    StateNotifierProvider<VisitorFormNotifier, AsyncValue<Visitor?>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorFormNotifier(repository, ref);
});
