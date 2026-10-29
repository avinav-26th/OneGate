import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_errors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_status.dart';
import '../controllers/visitor_list_controller.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/visitor_card.dart';
import 'recycle_bin_screen.dart';
import 'visitor_details_screen.dart';
import 'visitor_form_screen.dart';

// visitor directory with search filter chips and lazy loading
class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(visitorSearchQueryProvider),
    );
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  // infinite scroll listener to load next batch
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (ref.read(hasMoreVisitorsProvider)) {
        ref.read(visitorListNotifierProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openDetails(Visitor visitor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitorDetailsScreen(visitor: visitor),
      ),
    );
  }

  void _openEdit(Visitor visitor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitorFormScreen(existingVisitor: visitor),
      ),
    );
  }

  // soft delete visitor with 3-second undo snackbar
  void _confirmDelete(Visitor visitor) {
    DeleteDialog.show(
      context,
      visitorName: visitor.name,
      onConfirm: () async {
        await ref
            .read(visitorListNotifierProvider.notifier)
            .softDeleteVisitor(visitor.id);
        if (mounted) {
          AppSnackBar.info(
            context,
            'Moved ${visitor.name} to Recycle Bin',
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.mintTeal,
              onPressed: () {
                ref.read(visitorListNotifierProvider.notifier).restoreVisitor(visitor.id);
              },
            ),
          );
        }
      },
    );
  }

  // bottom sheet to change sort order
  void _showSortOptions() {
    final currentSort = ref.read(visitorSortOptionProvider);
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.borderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Sort Visitors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                ...VisitorSortOption.values.map((opt) {
                  final isSelected = opt == currentSort;
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    dense: true,
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.mintTeal : AppColors.navy)
                            : AppColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.mintTeal, size: 20)
                        : null,
                    onTap: () {
                      ref.read(visitorSortOptionProvider.notifier).state = opt;
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = AppColors.isDark(context);
    final groupedAsync = ref.watch(groupedVisitorsProvider);
    final selectedProject = ref.watch(selectedProjectFilterProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);
    final quickFilter = ref.watch(visitorQuickFilterProvider);
    final filterCounts = ref.watch(filterCountsProvider);
    final availableProjects = ref.watch(availableProjectsProvider);

    final currentFilterCount = switch (quickFilter) {
      VisitorQuickFilter.all => filterCounts.totalCount,
      VisitorQuickFilter.totalToday => filterCounts.totalToday,
      VisitorQuickFilter.currentlyIn => filterCounts.currentlyIn,
      VisitorQuickFilter.checkedOutToday => filterCounts.checkedOutToday,
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.backgroundOf(context),
        title: Text(
          AppStrings.visitorRegistry,
          style: TextStyle(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_delete_outlined, color: AppColors.textPrimaryOf(context)),
            tooltip: AppStrings.recycleBin,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RecycleBinScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
          if (quickFilter != VisitorQuickFilter.all)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintTeal.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mintTeal.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: isDark ? AppColors.mintTeal : const Color(0xFF0E8B75),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by: ${quickFilter.label} ($currentFilterCount)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.mintTeal : const Color(0xFF0E8B75),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(visitorQuickFilterProvider.notifier).state =
                          VisitorQuickFilter.all;
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isDark ? AppColors.mintTeal : const Color(0xFF0E8B75),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(visitorSearchQueryProvider.notifier).state = val;
                        ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                      },
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimaryOf(context)),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceOf(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        hintText: 'Search by visitor name or mobile...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondaryOf(context)),
                        prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondaryOf(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.borderOf(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.borderOf(context)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: AppColors.mintTeal, width: 1.5),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 16, color: AppColors.textSecondaryOf(context)),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(visitorSearchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showSortOptions,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: Center(
                      child: Icon(Icons.sort_rounded, color: AppColors.textPrimaryOf(context), size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                FilterChip(
                  shape: const StadiumBorder(),
                  label: Text('All (${filterCounts.totalCount})'),
                  selected: selectedProject == null &&
                      selectedStatus == null &&
                      quickFilter == VisitorQuickFilter.all,
                  onSelected: (_) {
                    ref.read(selectedProjectFilterProvider.notifier).state = null;
                    ref.read(selectedStatusFilterProvider.notifier).state = null;
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        VisitorQuickFilter.all;
                    ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  shape: const StadiumBorder(),
                  label: Text('Today (${filterCounts.totalToday})'),
                  selected: quickFilter == VisitorQuickFilter.totalToday,
                  onSelected: (selected) {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        selected ? VisitorQuickFilter.totalToday : VisitorQuickFilter.all;
                    ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  shape: const StadiumBorder(),
                  label: Text('Currently In (${filterCounts.currentlyIn})'),
                  selected: quickFilter == VisitorQuickFilter.currentlyIn,
                  onSelected: (selected) {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        selected ? VisitorQuickFilter.currentlyIn : VisitorQuickFilter.all;
                    ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  shape: const StadiumBorder(),
                  label: Text('Checked Out (${filterCounts.checkedOutToday})'),
                  selected: quickFilter == VisitorQuickFilter.checkedOutToday,
                  onSelected: (selected) {
                    ref.read(visitorQuickFilterProvider.notifier).state =
                        selected ? VisitorQuickFilter.checkedOutToday : VisitorQuickFilter.all;
                    ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                  },
                ),
                const SizedBox(width: 6),
                ...availableProjects.map((proj) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        shape: const StadiumBorder(),
                        label: Text(proj),
                        selected: selectedProject == proj,
                        onSelected: (selected) {
                          ref.read(selectedProjectFilterProvider.notifier).state =
                              selected ? proj : null;
                          ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                        },
                      ),
                    )),
                ...VisitorStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        shape: const StadiumBorder(),
                        label: Text(status.label),
                        selected: selectedStatus == status,
                        onSelected: (selected) {
                          ref.read(selectedStatusFilterProvider.notifier).state =
                              selected ? status : null;
                          ref.read(visitorDisplayLimitProvider.notifier).state = 15;
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              color: isDark ? AppColors.mintTeal : AppColors.navy,
              onRefresh: () async {
                await ref.read(visitorListNotifierProvider.notifier).refresh();
              },
              child: groupedAsync.when(
                data: (groupedMap) {
                  if (groupedMap.isEmpty) {
                    final isFiltered = _searchController.text.isNotEmpty ||
                        selectedProject != null ||
                        selectedStatus != null ||
                        quickFilter != VisitorQuickFilter.all;
                    return EmptyStateWidget(
                      icon: isFiltered ? Icons.search_off : Icons.people_outline,
                      title: isFiltered ? 'No matching visitors' : 'No visitors registered yet',
                      message: isFiltered
                          ? 'Try adjusting your search criteria or clearing filters.'
                          : 'Register your first visitor using the button below or via Dashboard.',
                      actionLabel: isFiltered ? 'Clear Filters' : 'Register Visitor',
                      onAction: () {
                        if (isFiltered) {
                          _searchController.clear();
                          ref.read(visitorSearchQueryProvider.notifier).state = '';
                          ref.read(selectedProjectFilterProvider.notifier).state = null;
                          ref.read(selectedStatusFilterProvider.notifier).state = null;
                          ref.read(visitorQuickFilterProvider.notifier).state =
                              VisitorQuickFilter.all;
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VisitorFormScreen(),
                            ),
                          );
                        }
                      },
                    );
                  }

                  final sections = groupedMap.entries.toList();
                  final hasMore = ref.watch(hasMoreVisitorsProvider);

                  // paginated list rendering with progressive bottom shimmer
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 140, top: 4),
                    itemCount: sections.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, sectionIndex) {
                      if (sectionIndex >= sections.length) {
                        return const ShimmerLoading(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: VisitorCardShimmer(),
                          ),
                        );
                      }
                      final entry = sections[sectionIndex];
                      final sectionTitle = entry.key;
                      final visitors = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Row(
                              children: [
                                Text(
                                  sectionTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryOf(context),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.chipOf(context),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${visitors.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...visitors.map((visitor) => VisitorCard(
                                visitor: visitor,
                                onTap: () => _openDetails(visitor),
                                onEdit: () => _openEdit(visitor),
                                onDelete: () => _confirmDelete(visitor),
                              )),
                        ],
                      );
                    },
                  );
                },
                loading: () => const VisitorListShimmer(),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppErrors.networkGeneral,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
