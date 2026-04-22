// lib/screens/ticket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/ticket_provider.dart';
import '../domain/entities/ticket_entity.dart';
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
  bool _loading = true;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.delayed(const Duration(milliseconds: 1000),
        () => mounted ? setState(() => _loading = false) : null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TicketEntity> _filterTickets(List<TicketEntity> tickets, int tabIndex) {
    List<TicketEntity> filtered;
    switch (tabIndex) {
      case 1:
        filtered = tickets.where((t) => t.status == TicketStatus.open).toList();
        break;
      case 2:
        filtered =
            tickets.where((t) => t.status == TicketStatus.inProgress).toList();
        break;
      case 3:
        filtered = tickets.where((t) => t.status == TicketStatus.done).toList();
        break;
      default:
        filtered = tickets;
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTickets = ref.watch(userTicketsProvider);

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
        bottom: allTickets.when(
          data: (tickets) {
            final stats = (
              total: tickets.length,
              open:
                  tickets.where((t) => t.status == TicketStatus.open).length,
              progress: tickets
                  .where((t) => t.status == TicketStatus.inProgress)
                  .length,
              done: tickets.where((t) => t.status == TicketStatus.done).length,
            );
            return TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Semua (${stats.total})'),
                Tab(text: 'Open (${stats.open})'),
                Tab(text: 'Progress (${stats.progress})'),
                Tab(text: 'Done (${stats.done})'),
              ],
            );
          },
          loading: () => TabBar(tabs: [Tab(), Tab(), Tab(), Tab()]),
          error: (err, stack) =>
              TabBar(tabs: [Tab(), Tab(), Tab(), Tab()]),
        ),
      ),
      body: _loading
          ? ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(),
            )
          : allTickets.when(
              data: (tickets) {
                return TabBarView(
                  controller: _tabController,
                  children: List.generate(4, (tabIndex) {
                    final filtered = _filterTickets(tickets, tabIndex);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada tiket',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return TicketCard(
                          ticket: filtered[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(
                                ticketId: filtered[index].id,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: 300.ms);
                      },
                    );
                  }),
                );
              },
              loading: () => ListView.builder(
                itemCount: 4,
                itemBuilder: (_, __) => const ShimmerCard(),
              ),
              error: (err, stack) =>
                  Center(child: Text('Error loading tickets: $err')),
            ),
    );
  }
}
