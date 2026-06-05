import 'package:flutter/material.dart';

/// A reusable dashboard section header with title text and an RFC badge.
class DashboardHeader extends StatelessWidget {
  final String title;
  final String badgeLabel;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badgeLabel,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
