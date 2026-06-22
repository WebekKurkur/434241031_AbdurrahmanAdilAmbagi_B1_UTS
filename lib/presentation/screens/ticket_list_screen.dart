// lib/presentation/screens/ticket_list_screen.dart
//
// Phase G1: switched from `userTicketsProvider` (load everything)
// to `paginatedTicketsProvider` (page-at-a-time with lazy
// loading). Each tab keeps its own page state via the
// `.family` keyed on the tab's `TicketStatus?`.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/paginated_tickets_provider.dart';
import '../../domain/entities/ticket_entity.dart';
import '../theme/app_theme.dart';
import '../widgets/ticket_card.dart';
import '../widgets/shimmer_card.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  /// One ScrollController per tab. Tabs are recreated when the
  /// user switches to a different filter so each tab keeps its
  /// own scroll offset.
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    for (var i = 0; i < 5; i++) {
      final ctrl = ScrollController();
      ctrl.addListener(() {
        if (!ctrl.hasClients) return;
        // Trigger a fetch when within 200 px of the bottom (the
        // "80%" pre-fetch rule from the G1 spec, expressed in
        // pixels because flutter's ScrollController doesn't know
        // its own visible extent).
        if (ctrl.position.pixels >=
            ctrl.position.maxScrollExtent - 200) {
          ref
              .read(paginatedTicketsProvider(_statusForTab(i)).notifier)
              .loadNextPage();
        }
      });
      _scrollControllers[i] = ctrl;
    }
  }

  void _onTabChanged() {
    // Trigger a rebuild so the tab's badge counts refresh.
    setState(() {});
  }

  TicketStatus? _statusForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return TicketStatus.open;
      case 2:
        return TicketStatus.assigned;
      case 3:
        return TicketStatus.inProgress;
      case 4:
        return TicketStatus.closed;
      default:
        return null; // "Semua" — no status filter
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    for (final ctrl in _scrollControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<TicketEntity> _filterTickets(List<TicketEntity> tickets) {
    if (_searchQuery.isEmpty) return tickets;
    final q = _searchQuery.toLowerCase();
    return tickets
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari tiket...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 16),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabBar(isDark: isDark, controller: _tabController),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (tabIndex) {
          return _TabBody(
            tabIndex: tabIndex,
            statusFilter: _statusForTab(tabIndex),
            scrollController: _scrollControllers[tabIndex]!,
            searchQuery: _searchQuery,
            filterFn: _filterTickets,
          );
        }),
      ),
    );
  }
}

class _TabBar extends ConsumerWidget {
  final bool isDark;
  final TabController controller;
  const _TabBar({required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch each tab's state for the count badges. The provider
    // is keyed by the tab's status filter, so each tab keeps its
    // own page state.
    final semua = ref.watch(paginatedTicketsProvider(null));
    final open = ref.watch(paginatedTicketsProvider(TicketStatus.open));
    final assigned =
        ref.watch(paginatedTicketsProvider(TicketStatus.assigned));
    final inProgress =
        ref.watch(paginatedTicketsProvider(TicketStatus.inProgress));
    final closed = ref.watch(paginatedTicketsProvider(TicketStatus.closed));

    int count(PaginatedTicketsState s) => s.totalCount;

    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      labelColor: AppColors.primary,
      unselectedLabelColor:
          isDark ? AppColors.textSecondary : AppColors.textMuted,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: [
        Tab(text: 'Semua (${count(semua)})'),
        Tab(text: 'Open (${count(open)})'),
        Tab(text: 'Assigned (${count(assigned)})'),
        Tab(text: 'Progress (${count(inProgress)})'),
        Tab(text: 'Closed (${count(closed)})'),
      ],
    );
  }
}

class _TabBody extends ConsumerWidget {
  final int tabIndex;
  final TicketStatus? statusFilter;
  final ScrollController scrollController;
  final String searchQuery;
  final List<TicketEntity> Function(List<TicketEntity>) filterFn;

  const _TabBody({
    required this.tabIndex,
    required this.statusFilter,
    required this.scrollController,
    required this.searchQuery,
    required this.filterFn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paginatedTicketsProvider(statusFilter));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.loading && state.tickets.isEmpty) {
      return ListView.builder(
        controller: scrollController,
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }

    if (state.tickets.isEmpty && !state.loading) {
      return _EmptyState(isDark: isDark);
    }

    final filtered = filterFn(state.tickets);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(paginatedTicketsProvider(statusFilter).notifier)
          .refresh(),
      child: ListView.builder(
        controller: scrollController,
        itemCount: filtered.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            // "Load more" footer
            return _LoadMoreFooter(
              isDark: isDark,
              loading: state.loading,
              onTap: () => ref
                  .read(paginatedTicketsProvider(statusFilter).notifier)
                  .loadNextPage(),
            );
          }
          return TicketCard(
            ticket: filtered[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TicketDetailScreen(ticketId: filtered[index].id),
              ),
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 30 * index),
                duration: 300.ms,
              );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tiket',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final bool isDark;
  final bool loading;
  final VoidCallback onTap;
  const _LoadMoreFooter({
    required this.isDark,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text('Muat Lebih Banyak'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
      ),
    );
  }
}