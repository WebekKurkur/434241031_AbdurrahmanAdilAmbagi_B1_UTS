// lib/presentation/screens/ticket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/paginated_tickets_provider.dart';
import '../theme/app_semantic.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/ticket_list_card.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  /// Currently selected filter chip. `null` = All.
  TicketStatus? _activeFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(paginatedTicketsProvider(_activeFilter).notifier).loadNextPage();
    }
  }

  void _onFilterTap(TicketStatus? filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
    ref.read(paginatedTicketsProvider(filter).notifier).setStatusFilter(filter);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  List<TicketEntity> _filterBySearch(List<TicketEntity> tickets) {
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
    final c = context.semantic;
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(paginatedTicketsProvider(_activeFilter));

    return Scaffold(
      backgroundColor: c.surface,
      body: Stack(
        children: [
          // Scrollable list (under the sticky header).
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(paginatedTicketsProvider(_activeFilter).notifier)
                  .refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Top spacer so the sticky header doesn't overlap
                  // the first card. Header height = 18.75 (top) +
                  // 30 (title) + 18 (subtitle) + 15 (margin) +
                  // 37.5 (search) + 11.25 + 41.25 (chip row) +
                  // 11.25 (bottom) = 183. We use 184 for safety.
                  const SliverToBoxAdapter(child: SizedBox(height: 184)),
                  _buildBodySlivers(state, user),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
          // Sticky frosted header.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StickyHeader(
              searchController: _searchController,
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              activeFilter: _activeFilter,
              onFilterChanged: _onFilterTap,
              totalCount: state.totalCount,
              visibleCount: state.tickets.length,
              onNewTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              ),
              showNewButton: user?.role == UserRole.user,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySlivers(
    PaginatedTicketsState state,
    dynamic user,
  ) {
    if (state.loading && state.tickets.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(18.75, 11.25, 18.75, 0),
        sliver: SliverList.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 11.25),
            child: ShimmerCard(),
          ),
        ),
      );
    }

    final filtered = _filterBySearch(state.tickets);

    if (filtered.isEmpty && !state.loading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(hasFilter: _searchQuery.isNotEmpty),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18.75, 11.25, 18.75, 0),
      sliver: SliverList.builder(
        itemCount: filtered.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return _LoadMoreFooter(
              loading: state.loading,
              onTap: () => ref
                  .read(paginatedTicketsProvider(_activeFilter).notifier)
                  .loadNextPage(),
            );
          }
          final ticket = filtered[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == filtered.length - 1 ? 0 : 11.25),
            child: TicketListCard(
              ticket: ticket,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: ticket.id),
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: Duration(milliseconds: 30 * index),
                    duration: 300.ms)
                .slideY(begin: 0.05),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Sticky header (Figma nodes 8071:1196-1236)
// ─────────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final TicketStatus? activeFilter;
  final ValueChanged<TicketStatus?> onFilterChanged;
  final int totalCount;
  final int visibleCount;
  final VoidCallback onNewTap;
  final bool showNewButton;

  const _StickyHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.totalCount,
    required this.visibleCount,
    required this.onNewTap,
    required this.showNewButton,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return ClipRect(
      child: BackdropContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18.75, 18.75, 18.75, 11.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row: title block + new button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tickets',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                            letterSpacing: -0.48,
                            height: 1.25,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '$visibleCount of $totalCount tickets',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showNewButton) _NewButton(onTap: onNewTap),
                ],
              ),
              const SizedBox(height: 15),
              _SearchField(
                controller: searchController,
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 11.25),
              _FilterChips(
                active: activeFilter,
                onChanged: onFilterChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackdropContainer extends StatelessWidget {
  final Widget child;
  const BackdropContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Frosted-glass header per Figma spec. In light mode the
    // surface is `#f5f7fa` at ~80% alpha; in dark mode it flips
    // to `#0f1115` at the same alpha via `c.surfaceFrosted`.
    final c = context.semantic;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceFrosted,
        border: Border(
          bottom: BorderSide(
            color: c.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Container(
      height: 37.5,
      decoration: BoxDecoration(
        // Option A: subtle inset — tintNeutral bg + 1px border.
        // Matches the admin user-list search + auth fields.
        color: c.tintNeutral,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.25),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 15,
              color: c.textHint,
            ),
            const SizedBox(width: 7.5),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'Search by title or ID…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: c.textHint,
                    fontWeight: FontWeight.w400,
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

class _FilterChips extends StatelessWidget {
  final TicketStatus? active;
  final ValueChanged<TicketStatus?> onChanged;
  const _FilterChips({required this.active, required this.onChanged});

  static const _chips = <_ChipSpec>[
    _ChipSpec(label: 'All', status: null),
    _ChipSpec(label: 'Open', status: TicketStatus.open),
    _ChipSpec(label: 'In Progress', status: TicketStatus.inProgress),
    _ChipSpec(label: 'Assigned', status: TicketStatus.assigned),
    _ChipSpec(label: 'Closed', status: TicketStatus.closed),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41.25,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The negative-margin container from Figma (left: -3.75,
          // width: 352) gives chips horizontal overflow off the
          // edge so the scroll feels natural.
          Positioned(
            left: -3.75,
            top: 11.25,
            right: -3.75,
            bottom: 0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 3.75),
              physics: const BouncingScrollPhysics(),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 3.75),
              itemBuilder: (context, i) {
                final chip = _chips[i];
                final isActive = chip.status == active;
                return _FilterChip(
                  label: chip.label,
                  active: isActive,
                  onTap: () => onChanged(chip.status),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSpec {
  final String label;
  final TicketStatus? status;
  const _ChipSpec({required this.label, required this.status});
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    // Active chip inverts to `c.textPrimary` (light: black,
    // dark: near-white) for high contrast against `c.surface`.
    // Inactive chip is `c.surfaceCard` with `c.border` outline.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12.25),
        decoration: BoxDecoration(
          color: active ? c.textPrimary : c.surfaceCard,
          border: Border.all(
            color: active ? c.textPrimary : c.border,
          ),
          borderRadius: BorderRadius.circular(33554400),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? c.surface : c.textSecondary,
            letterSpacing: -0.06,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Brand blue — fixed in both modes.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 33.75,
        padding: const EdgeInsets.symmetric(horizontal: 11.25),
        decoration: BoxDecoration(
          color: AppColors.authPrimary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: Colors.white),
            SizedBox(width: 5.625),
            Text(
              'New',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty + footer states
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final c = context.semantic;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.inbox_rounded,
            size: 56,
            color: c.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No tickets match your search' : 'No tickets yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasFilter
                ? 'Try a different keyword'
                : 'New tickets will appear here',
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _LoadMoreFooter({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.authPrimary,
                ),
                child: const Text('Load more'),
              ),
      ),
    );
  }
}
