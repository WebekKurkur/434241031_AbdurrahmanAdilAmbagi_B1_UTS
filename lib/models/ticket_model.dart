// lib/models/ticket_model.dart
// DEPRECATED: Use domain/entities instead
// This file is kept for backwards compatibility only

import '../domain/entities/ticket_entity.dart';
import '../domain/entities/user_entity.dart';

// Compatibility aliases for old code
// TODO: Refactor all screens to use domain entities directly
typedef Ticket = TicketEntity;
typedef Comment = CommentEntity;
