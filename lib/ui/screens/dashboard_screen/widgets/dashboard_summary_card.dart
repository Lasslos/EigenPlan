import 'package:flutter/material.dart';

/// One dashboard section: a title, arbitrary [child] content, and an optional
/// "Alle anzeigen" button linking to the full screen for that data.
class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    required this.title,
    required this.child,
    this.onShowMore,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onShowMore;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
            if (onShowMore != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onShowMore,
                  child: const Text('Alle anzeigen'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
