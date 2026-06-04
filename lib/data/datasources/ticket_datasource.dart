// lib/data/datasources/ticket_datasource.dart
//
// Supabase-backed implementation. Reads and writes rows in
// the `tickets` and `comments` tables.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../models/ticket_model.dart';

class TicketDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  // --------------------------------------------------------- reads

  Future<List<TicketModel>> getTickets() async {
    final userId = _client.auth.currentUser?.id ?? 'anon';
    debugPrint('[tickets] getTickets() as user=$userId');
    try {
      final res = await _client
          .from('tickets')
          .select('*, creator:created_by(name), assignee:assigned_to(name)')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));
      final rows = res.cast<Map<String, dynamic>>();
      debugPrint('[tickets] getTickets() returned ${rows.length} rows');
      final ids = rows.map((r) => r['id'] as String).toList();
      final comments = await _fetchCommentsForTickets(ids);
      return rows
          .map((j) => _toModel(j, comments[j['id']] ?? const []))
          .toList();
    } catch (e, st) {
      debugPrint('[tickets] getTickets() FAILED: $e\n$st');
      rethrow;
    }
  }

  /// Raw row count under the current RLS context. Useful for
  /// diagnostics: the UI can show this next to the filtered count
  /// so a user can tell whether an empty list is "no rows in DB"
  /// or "RLS is hiding rows from this role".
  Future<int> countTickets() async {
    final res = await _client
        .from('tickets')
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 8));
    debugPrint('[tickets] countTickets() as user='
        '${_client.auth.currentUser?.id ?? "anon"} returned $res');
    return res;
  }

  /// Resolve a public `ticket_code` (e.g. "TKT-001") to the row's
  /// uuid primary key. The `tickets.id` column is a uuid, so any
  /// code-shaped value must be translated before being used in an
  /// `eq('id', ...)` / `update` / `delete` filter.
  ///
  /// Accepts either a public code or an already-resolved uuid.
  /// Returns `null` if the code doesn't match any row.
  Future<String?> _resolveTicketUuid(String idOrCode) async {
    if (idOrCode.contains('-') && idOrCode.length == 36) {
      return idOrCode; // already a uuid
    }
    final res = await _client
        .from('tickets')
        .select('id')
        .eq('ticket_code', idOrCode)
        .maybeSingle();
    return res?['id'] as String?;
  }

  Future<TicketModel?> getTicketById(String idOrCode) async {
    // Tickets are looked up by their public `ticket_code` (e.g. "TKT-001")
    // in the UI, but the table's primary key is a `uuid` `id`. The query
    // tries the public code first; if no match, it falls back to the uuid
    // lookup. (`ticket_code` is text, so a uuid-shaped value never causes
    // a type error in the first branch.)
    var res = await _client
        .from('tickets')
        .select('*, creator:created_by(name), assignee:assigned_to(name)')
        .eq('ticket_code', idOrCode)
        .maybeSingle();
    res ??= await _client
        .from('tickets')
        .select('*, creator:created_by(name), assignee:assigned_to(name)')
        .eq('id', idOrCode)
        .maybeSingle();
    if (res == null) return null;
    // Use the actual uuid for the comments lookup — _fetchCommentsForTickets
    // keys by the foreign-key column on `comments.ticket_id`, which is the
    // uuid `tickets.id`, not `ticket_code`.
    final ticketUuid = res['id'] as String;
    final comments = await _fetchCommentsForTickets([ticketUuid]);
    return _toModel(res, comments[ticketUuid] ?? const []);
  }

  Future<Map<String, List<CommentModel>>> _fetchCommentsForTickets(
      List<String> ticketIds) async {
    if (ticketIds.isEmpty) return {};
    final res = await _client
        .from('comments')
        .select('*, author:author_id(name, role)')
        .inFilter('ticket_id', ticketIds)
        .order('created_at', ascending: true);
    final out = <String, List<CommentModel>>{
      for (final id in ticketIds) id: <CommentModel>[],
    };
    for (final row in res.cast<Map<String, dynamic>>()) {
      out[row['ticket_id'] as String]!.add(_toComment(row));
    }
    return out;
  }

  // --------------------------------------------------------- writes

  Future<TicketModel> addTicket({
    required String title,
    required String description,
    required String category,
    String? imageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to create a ticket');
    }
    final code =
        'TKT-${DateTime.now().millisecondsSinceEpoch.remainder(100000).toString().padLeft(3, '0')}';
    final inserted = await _client.from('tickets').insert({
      'ticket_code': code,
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'status': 'open',
      'created_by': user.id,
    }).select(
        '*, creator:created_by(name), assignee:assigned_to(name)').single();
    return _toModel(inserted, const []);
  }

  /// Update the status of a ticket. [ticketId] can be either the
  /// public `ticket_code` (e.g. "TKT-001") or the row's uuid.
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    final ticketUuid = await _resolveTicketUuid(ticketId);
    if (ticketUuid == null) {
      throw FormatException(
        'updateTicketStatus: no ticket with id/code "$ticketId"',
      );
    }
    debugPrint('[tickets] updateTicketStatus id=$ticketUuid status=${status.name}');
    await _client
        .from('tickets')
        .update({'status': status.name})
        .eq('id', ticketUuid)
        .timeout(const Duration(seconds: 8));
  }

  /// Assign a ticket to a helpdesk user.
  ///
  /// [ticketId] can be either the public `ticket_code` or the row's uuid.
  /// [assignedTo] is the public `username` of the helpdesk user
  /// (e.g. "helpdesk") or their `name` (e.g. "Budi Santoso") or
  /// their `id` (uuid). The method resolves it to the user's uuid
  /// before writing, because `tickets.assigned_to` is a uuid
  /// foreign key.
  Future<void> assignTicket(String ticketId, String assignedTo) async {
    final ticketUuid = await _resolveTicketUuid(ticketId);
    if (ticketUuid == null) {
      throw FormatException(
        'assignTicket: no ticket with id/code "$ticketId"',
      );
    }
    String? userId;
    if (assignedTo.contains('-') && assignedTo.length == 36) {
      // Already a uuid
      userId = assignedTo;
    } else {
      // Try by username first, then by name
      final byUsername = await _client
          .from('profiles')
          .select('id')
          .eq('username', assignedTo)
          .maybeSingle();
      if (byUsername != null) {
        userId = byUsername['id'] as String;
      } else {
        final byName = await _client
            .from('profiles')
            .select('id')
            .eq('name', assignedTo)
            .maybeSingle();
        userId = byName?['id'] as String;
      }
    }
    if (userId == null) {
      throw FormatException(
        'assignTicket: no profile matched "$assignedTo"',
      );
    }
    debugPrint('[tickets] assignTicket id=$ticketUuid to=$userId ($assignedTo)');
    await _client
        .from('tickets')
        .update({'assigned_to': userId})
        .eq('id', ticketUuid)
        .timeout(const Duration(seconds: 8));
  }

  /// All users with the helpdesk role. Used by the assign sheet so
  /// the user can pick from real profiles, not a hard-coded list.
  Future<List<Map<String, dynamic>>> getHelpdeskUsers() async {
    final res = await _client
        .from('profiles')
        .select('id, username, name, role, department')
        .eq('role', 'helpdesk')
        .order('name', ascending: true);
    return res.cast<Map<String, dynamic>>();
  }

  /// Resolve a public `ticket_code` (e.g. "TKT-001") to the row's
  /// uuid primary key. The `comments.ticket_id` column is a uuid FK,
  /// so any code-shaped value must be translated before insert.
  Future<String?> _ticketUuidFromCode(String idOrCode) =>
      _resolveTicketUuid(idOrCode);

  Future<void> addComment(
      String ticketId, String message, String author, UserRole role) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to comment');
    }
    final ticketUuid = await _ticketUuidFromCode(ticketId);
    if (ticketUuid == null) {
      throw FormatException(
        'addComment: no ticket with code "$ticketId"',
      );
    }
    await _client.from('comments').insert({
      'ticket_id': ticketUuid,
      'author_id': user.id,
      'message': message,
    });
  }

  // --------------------------------------------------------- realtime

  /// Stream of all ticket rows. Listens to INSERT / UPDATE / DELETE.
  Stream<List<TicketModel>> watchTickets() {
    return _client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => getTickets());
  }

  /// Stream of comments for one ticket. The caller may pass either
  /// a public `ticket_code` (e.g. "TKT-001") or the row's uuid —
  /// either is accepted and resolved to the uuid internally.
  Stream<List<CommentModel>> watchComments(String ticketId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .asyncMap((_) async {
          final uuid = await _ticketUuidFromCode(ticketId);
          if (uuid == null) return <CommentModel>[];
          final m = await _fetchCommentsForTickets([uuid]);
          return m[uuid] ?? const [];
        });
  }

  // --------------------------------------------------------- mappers

  TicketModel _toModel(
    Map<String, dynamic> j,
    List<CommentModel> comments,
  ) {
    return TicketModel(
      id: j['ticket_code'] as String? ?? j['id'] as String,
      title: j['title'] as String? ?? '',
      description: j['description'] as String? ?? '',
      status: _parseStatus(j['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(j['created_at'] as String),
      createdBy: (j['creator'] is Map ? (j['creator']['name'] ?? '') : ''),
      assignedTo:
          (j['assignee'] is Map ? (j['assignee']['name'] ?? '') : null),
      comments: comments,
      imageUrl: j['image_url'] as String?,
      category: j['category'] as String? ?? 'General',
    );
  }

  CommentModel _toComment(Map<String, dynamic> j) {
    final author = j['author'] is Map ? j['author'] as Map : const {};
    return CommentModel(
      id: j['id'] as String,
      author: (author['name'] as String?) ?? '',
      message: j['message'] as String? ?? '',
      createdAt: DateTime.parse(j['created_at'] as String),
      role: _parseRole((author['role'] as String?) ?? 'user'),
    );
  }

  TicketStatus _parseStatus(String s) {
    switch (s) {
      case 'open':
        return TicketStatus.open;
      case 'inProgress':
        return TicketStatus.inProgress;
      case 'done':
        return TicketStatus.done;
      default:
        return TicketStatus.open;
    }
  }

  UserRole _parseRole(String s) {
    return UserRole.values.firstWhere(
      (r) => r.name == s,
      orElse: () => UserRole.user,
    );
  }
}
