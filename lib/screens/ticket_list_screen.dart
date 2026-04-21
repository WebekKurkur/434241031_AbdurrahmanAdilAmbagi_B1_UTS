// lib/screens/ticket_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ticket_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ticket_card.dart';
import '../widgets/shimmer_card.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
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

  List<Ticket> _filterTickets(List<Ticket> tickets, int tabIndex) {
    List<Ticket> filtered;
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
    final provider = context.watch<AppProvider>();
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
        bottom: TabBar(
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
            Tab(
                text:
                    'Semua (${provider.userTickets.length})'),
            Tab(
                text:
                    'Open (${provider.openTickets})'),
            Tab(
                text:
                    'Progress (${provider.inProgressTickets})'),
            Tab(
                text:
                    'Done (${provider.doneTickets})'),
          ],
        ),
      ),
      body: _loading
          ? ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(),
            )
          : TabBarView(
              controller: _tabController,
              children: List.generate(4, (tabIndex) {
                final filtered =
                    _filterTickets(provider.userTickets, tabIndex);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada hasil untuk "$_searchQuery"'
                              : 'Tidak ada tiket',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return TicketCard(
                      ticket: filtered[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(
                              ticketId: filtered[index].id),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 50 * index),
                            duration: 300.ms)
                        .slideX(begin: 0.05);
                  },
                );
              }),
            ),
    );
  }
}
