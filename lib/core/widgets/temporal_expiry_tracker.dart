import 'dart:async';
import 'package:flutter/material.dart';

class TemporalExpiryTracker extends StatefulWidget {
  final DateTime? validUntil;

  const TemporalExpiryTracker({
    super.key,
    required this.validUntil,
  });

  @override
  State<TemporalExpiryTracker> createState() => _TemporalExpiryTrackerState();
}

class _TemporalExpiryTrackerState extends State<TemporalExpiryTracker> {
  late final Stream<DateTime> _tickerStream;

  @override
  void initState() {
    super.initState();
    _tickerStream = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now().toUtc(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validUntil = widget.validUntil;
    if (validUntil == null) {
      return _buildBadge('PERSISTENT', Colors.grey);
    }

    return StreamBuilder<DateTime>(
      stream: _tickerStream,
      initialData: DateTime.now().toUtc(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now().toUtc();
        if (validUntil.isBefore(now)) {
          return _buildBadge('EXPIRED', Colors.orange);
        } else {
          return _buildBadge('ACTIVE', Colors.green);
        }
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
