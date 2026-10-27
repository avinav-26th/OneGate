import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/visitor.dart';
import '../../domain/visitor_status.dart';
import '../controllers/visitor_list_controller.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/visitor_card.dart';
import 'visitor_details_screen.dart';
import 'visitor_form_screen.dart';

class VisitorListScreen extends ConsumerStatefulWidget {
  const VisitorListScreen({super.key});

  @override
  ConsumerState<VisitorListScreen> createState() => _VisitorListScreenState();
}

class _VisitorListScreenState extends ConsumerState<VisitorListScreen>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _searchController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(visitorSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _confirmDelete(Visitor visitor) {
    DeleteDialog.show(
      context,
      visitorName: visitor.name,
      onConfirm: () async {
        await ref
            .read(visitorListNotifierProvider.notifier)
            .deleteVisitor(visitor.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visitor record deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final visitorsAsync = ref.watch(filteredVisitorsProvider);
    final selectedProject = ref.watch(selectedProjectFilterProvider);
    final selectedStatus = ref.watch(selectedStatusFilterProvider);
    final quickFilter = ref.watch(visitorQuickFilterProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFF4F7F8),
        title: const Text('Visitor Registry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const VisitorFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (quickFilter != VisitorQuickFilter.all)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF38DCC0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF38DCC0).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Color(0xFF0E8B75)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by: ${quickFilter.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0E8B75),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ref.read(visitorQuickFilterProvider.notifier).state =
                          VisitorQuickFilter.all;
                    },
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF0E8B75)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(visitorSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'Search by visitor name or mobile number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(visitorSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Projects'),
                  selected: selectedProject == null,
                  onSelected: (_) {
                    ref.read(selectedProjectFilterProvider.notifier).state = null;
                  },
                ),
                const SizedBox(width: 8),
                ...AppConstants.projects.map((proj) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(proj),
                        selected: selectedProject == proj,
                        onSelected: (selected) {
                          ref.read(selectedProjectFilterProvider.notifier).state =
                              selected ? proj : null;
                        },
                      ),
                    )),
                const SizedBox(width: 8),
                ...VisitorStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status.label),
                        selected: selectedStatus == status,
                        onSelected: (selected) {
                          ref.read(selectedStatusFilterProvider.notifier).state =
                              selected ? status : null;
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: const Color(0xFF142B3B),
              color: const Color(0xFF38DCC0),
              onRefresh: () async {
                await ref.read(visitorListNotifierProvider.notifier).refresh();
              },
              child: visitorsAsync.when(
                data: (visitors) {
                  if (visitors.isEmpty) {
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

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final visitor = visitors[index];
                      return VisitorCard(
                        visitor: visitor,
                        onTap: () => _openDetails(visitor),
                        onEdit: () => _openEdit(visitor),
                        onDelete: () => _confirmDelete(visitor),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading visitors: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(visitorListNotifierProvider.notifier).refresh();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
