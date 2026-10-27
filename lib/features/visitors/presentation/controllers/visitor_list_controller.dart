import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_repository.dart';
import '../../domain/visitor_status.dart';
import 'visitor_providers.dart';

enum VisitorQuickFilter {
  all('All'),
  totalToday('Today\'s Visitors'),
  currentlyIn('Currently In'),
  checkedOutToday('Checked Out Today');

  final String label;
  const VisitorQuickFilter(this.label);
}

final visitorSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedProjectFilterProvider = StateProvider<String?>((ref) => null);
final selectedStatusFilterProvider = StateProvider<VisitorStatus?>((ref) => null);
final visitorQuickFilterProvider = StateProvider<VisitorQuickFilter>((ref) => VisitorQuickFilter.all);

class VisitorListNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  final VisitorRepository _repository;

  VisitorListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadVisitors();
  }

  Future<void> loadVisitors() async {
    state = const AsyncValue.loading();
    try {
      final visitors = await _repository.getVisitors();
      state = AsyncValue.data(visitors);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final visitors = await _repository.getVisitors();
      state = AsyncValue.data(visitors);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteVisitor(String id) async {
    try {
      await _repository.deleteVisitor(id);
      state.whenData((list) {
        state = AsyncValue.data(list.where((v) => v.id != id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void upsertVisitor(Visitor visitor) {
    state.whenData((list) {
      final index = list.indexWhere((v) => v.id == visitor.id);
      if (index != -1) {
        final updatedList = List<Visitor>.from(list);
        updatedList[index] = visitor;
        state = AsyncValue.data(updatedList);
      } else {
        state = AsyncValue.data([visitor, ...list]);
      }
    });
  }
}

final visitorListNotifierProvider =
    StateNotifierProvider<VisitorListNotifier, AsyncValue<List<Visitor>>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return VisitorListNotifier(repository);
});

final recentVisitorsProvider = Provider<AsyncValue<List<Visitor>>>((ref) {
  final visitorsAsync = ref.watch(visitorListNotifierProvider);
  return visitorsAsync.whenData((visitors) {
    final list = List<Visitor>.from(visitors);
    list.sort((a, b) {
      final timeA = a.checkInTime ?? a.createdAt;
      final timeB = b.checkInTime ?? b.createdAt;
      return timeB.compareTo(timeA);
    });
    return list;
  });
});

final filteredVisitorsProvider = Provider<AsyncValue<List<Visitor>>>((ref) {
  final visitorsAsync = ref.watch(visitorListNotifierProvider);
  final searchQuery = ref.watch(visitorSearchQueryProvider).trim().toLowerCase();
  final projectFilter = ref.watch(selectedProjectFilterProvider);
  final statusFilter = ref.watch(selectedStatusFilterProvider);
  final quickFilter = ref.watch(visitorQuickFilterProvider);

  return visitorsAsync.whenData((visitors) {
    return visitors.where((visitor) {
      final matchesSearch = searchQuery.isEmpty ||
          visitor.name.toLowerCase().contains(searchQuery) ||
          visitor.mobile.contains(searchQuery);

      final matchesProject = projectFilter == null || visitor.project == projectFilter;

      final matchesStatus = statusFilter == null || visitor.status == statusFilter;

      final matchesQuickFilter = switch (quickFilter) {
        VisitorQuickFilter.all => true,
        VisitorQuickFilter.totalToday => DateFormatter.isToday(visitor.createdAt),
        VisitorQuickFilter.currentlyIn => visitor.status == VisitorStatus.checkedIn,
        VisitorQuickFilter.checkedOutToday =>
            visitor.status == VisitorStatus.checkedOut && DateFormatter.isToday(visitor.checkOutTime),
      };

      return matchesSearch && matchesProject && matchesStatus && matchesQuickFilter;
    }).toList();
  });
});
