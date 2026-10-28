import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/data_orchestrator.dart';
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

enum VisitorSortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  nameAsc('Name (A to Z)'),
  nameDesc('Name (Z to A)');

  final String label;
  const VisitorSortOption(this.label);
}

final visitorSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedProjectFilterProvider = StateProvider<String?>((ref) => null);
final selectedStatusFilterProvider = StateProvider<VisitorStatus?>((ref) => null);
final visitorQuickFilterProvider = StateProvider<VisitorQuickFilter>((ref) => VisitorQuickFilter.all);
final visitorSortOptionProvider = StateProvider<VisitorSortOption>((ref) => VisitorSortOption.newest);
final visitorDisplayLimitProvider = StateProvider<int>((ref) => 15);

class VisitorListNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  final VisitorRepository _repository;
  final Ref _ref;

  VisitorListNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadVisitors();
  }

  Future<void> loadVisitors() async {
    try {
      final cached = await _repository.getVisitors(forceRefresh: false);
      state = AsyncValue.data(cached);
      _silentSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _silentSync() async {
    try {
      final fresh = await _repository.getVisitors(forceRefresh: true);
      state = AsyncValue.data(fresh);
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      final visitors = await _repository.getVisitors(forceRefresh: true);
      state = AsyncValue.data(visitors);
      _ref.read(recycleBinProvider.notifier).loadBin();
    } catch (_) {
      final fallback = await _repository.getVisitors(forceRefresh: false);
      state = AsyncValue.data(fallback);
    }
  }

  Future<void> softDeleteVisitor(String id) async {
    try {
      await _repository.softDeleteVisitor(id);
      state.whenData((list) {
        state = AsyncValue.data(list.where((v) => v.id.trim().toLowerCase() != id.trim().toLowerCase()).toList());
      });
      _ref.read(recycleBinProvider.notifier).loadBin();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteVisitor(String id) => softDeleteVisitor(id);

  Future<void> restoreVisitor(String id) async {
    try {
      await _repository.restoreVisitor(id);
      final list = await _repository.getVisitors(forceRefresh: false);
      state = AsyncValue.data(list);
      _ref.read(recycleBinProvider.notifier).loadBin();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> hardDeleteVisitor(String id) async {
    try {
      await _repository.hardDeleteVisitor(id);
      state.whenData((list) {
        state = AsyncValue.data(list.where((v) => v.id.trim().toLowerCase() != id.trim().toLowerCase()).toList());
      });
      _ref.read(recycleBinProvider.notifier).loadBin();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void loadMore() {
    _ref.read(visitorDisplayLimitProvider.notifier).state += 15;
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
  return VisitorListNotifier(repository, ref);
});

class RecycleBinNotifier extends StateNotifier<AsyncValue<List<Visitor>>> {
  final VisitorRepository _repository;

  RecycleBinNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBin();
  }

  Future<void> loadBin() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getRecycleBinVisitors();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> restore(String id) async {
    try {
      await _repository.restoreVisitor(id);
      final remaining = await _repository.getRecycleBinVisitors();
      state = AsyncValue.data(remaining);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePermanently(String id) async {
    try {
      await _repository.hardDeleteVisitor(id);
      final remaining = await _repository.getRecycleBinVisitors();
      state = AsyncValue.data(remaining);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> emptyBin() async {
    try {
      await _repository.emptyRecycleBin();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recycleBinProvider =
    StateNotifierProvider<RecycleBinNotifier, AsyncValue<List<Visitor>>>((ref) {
  final repository = ref.watch(visitorRepositoryProvider);
  return RecycleBinNotifier(repository);
});

final availableProjectsProvider = Provider<List<String>>((ref) {
  final visitorsAsync = ref.watch(visitorListNotifierProvider);
  final defaults = ['Project A', 'Project B', 'Project C'];
  final set = Set<String>.from(defaults);
  visitorsAsync.whenData((list) {
    for (final v in list) {
      if (v.project.trim().isNotEmpty) {
        set.add(v.project.trim());
      }
    }
  });
  final sorted = set.toList()..sort();
  return sorted;
});

final filterCountsProvider = Provider<ComputedTierMetrics>((ref) {
  final visitorsAsync = ref.watch(visitorListNotifierProvider);
  return visitorsAsync.maybeWhen(
    data: (visitors) => ComputedTierMetrics.fromVisitors(visitors),
    orElse: () => const ComputedTierMetrics(
      totalCount: 0,
      totalToday: 0,
      currentlyIn: 0,
      checkedOutToday: 0,
      recycleBinCount: 0,
    ),
  );
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
  final sortOption = ref.watch(visitorSortOptionProvider);

  return visitorsAsync.whenData((visitors) {
    final filtered = visitors.where((visitor) {
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

    filtered.sort((a, b) {
      switch (sortOption) {
        case VisitorSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case VisitorSortOption.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case VisitorSortOption.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case VisitorSortOption.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      }
    });

    return filtered;
  });
});

final hasMoreVisitorsProvider = Provider<bool>((ref) {
  final filteredAsync = ref.watch(filteredVisitorsProvider);
  final limit = ref.watch(visitorDisplayLimitProvider);
  return filteredAsync.maybeWhen(
    data: (list) => list.length > limit,
    orElse: () => false,
  );
});

final groupedVisitorsProvider = Provider<AsyncValue<Map<String, List<Visitor>>>>((ref) {
  final filteredAsync = ref.watch(filteredVisitorsProvider);
  final limit = ref.watch(visitorDisplayLimitProvider);
  final sortOption = ref.watch(visitorSortOptionProvider);

  return filteredAsync.whenData((list) {
    final paginated = list.take(limit).toList();
    final map = <String, List<Visitor>>{};
    final isNameSorted = sortOption == VisitorSortOption.nameAsc || sortOption == VisitorSortOption.nameDesc;

    for (final v in paginated) {
      final groupKey = isNameSorted
          ? (v.name.isNotEmpty ? v.name[0].toUpperCase() : '#')
          : DateFormatter.getDateGroup(v.createdAt);
      map.putIfAbsent(groupKey, () => []).add(v);
    }
    return map;
  });
});
