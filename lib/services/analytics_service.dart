import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Lightweight client-side analytics queue. Events are buffered in
/// memory and flushed in batches to `POST /api/me/events`. Auth is
/// automatic via the Dio request interceptor — the customer token
/// wins when the user is logged in, otherwise the guest token is
/// attached, so the same call path serves both anonymous and
/// registered users.
///
/// Failures are swallowed and the batch is requeued for the next
/// tick; at steady state there is no backpressure on the UI thread.
class AnalyticsService {
  AnalyticsService._();

  static const _maxQueue = 200;
  static const _batchSize = 50;
  static const _flushInterval = Duration(seconds: 10);
  static const _flushThreshold = 20;

  static final Queue<_PendingEvent> _queue = Queue<_PendingEvent>();
  static Timer? _timer;
  static bool _flushing = false;

  /// Called once at app startup from [ApiService.init].
  static void init() {
    _timer ??= Timer.periodic(_flushInterval, (_) => _flush());
  }

  static void track(String type, {Map<String, dynamic>? payload}) {
    _queue.add(
      _PendingEvent(type, payload ?? const {}, DateTime.now().toUtc()),
    );
    while (_queue.length > _maxQueue) {
      _queue.removeFirst();
    }
    if (_queue.length >= _flushThreshold) {
      // Fire-and-forget; intentionally not awaited.
      _flush();
    }
  }

  static Future<void> _flush() async {
    if (_flushing || _queue.isEmpty) return;
    _flushing = true;
    try {
      final batch = <_PendingEvent>[];
      while (_queue.isNotEmpty && batch.length < _batchSize) {
        batch.add(_queue.removeFirst());
      }
      try {
        await ApiService.dio.post(
          '/api/me/events',
          data: {'events': batch.map((e) => e.toJson()).toList()},
        );
      } catch (e) {
        debugPrint(
          '[AnalyticsService] flush failed: $e — requeueing ${batch.length}',
        );
        for (final item in batch.reversed) {
          _queue.addFirst(item);
        }
        while (_queue.length > _maxQueue) {
          _queue.removeFirst();
        }
      }
    } finally {
      _flushing = false;
    }
  }
}

class _PendingEvent {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;

  _PendingEvent(this.type, this.payload, this.occurredAt);

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
        'occurred_at': occurredAt.toIso8601String(),
      };
}
