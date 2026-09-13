import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/homework_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/ui/screens/homework_screen/homework_screen.dart';
import 'package:your_schedule/ui/shared/course_chip.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/homework_grouping.dart';

const _windowDays = 7;
const _maxItemsShown = 4;

/// Upcoming homework due within the next [_windowDays] days, capped to
/// [_maxItemsShown] — "Alle anzeigen" is the only remaining path to [HomeworkScreen],
/// so it's always shown, even when this card's own filtered list is empty. Already
/// overdue homework is deliberately excluded here: on [HomeworkScreen] itself those
/// items sit collapsed behind "Zeige ältere Hausaufgaben", so the home screen — which
/// has no such toggle — shouldn't surface them either.
class HomeworkSummaryCard extends ConsumerWidget {
  const HomeworkSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final homework = ref.watch(homeworkOverviewProvider(session));

    final today = Date.now();
    final upcoming = splitHomeworkByDueDate(homework.homeWorks, today: today).upcoming;
    final items = upcoming.where((item) {
      if (item.completed) {
        return false;
      }
      final daysUntilDue = Date(item.endDate).differenceInDays(today);
      return daysUntilDue <= _windowDays;
    }).toList();

    final displayed = items.take(_maxItemsShown).toList();
    final remaining = items.length - displayed.length;

    return DashboardSummaryCard(
      title: 'Hausaufgaben',
      onShowMore: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeworkScreen()),
      ),
      child: items.isEmpty
          ? const Text('Keine Hausaufgaben in den nächsten 7 Tagen.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in displayed)
                  _HomeworkSummaryTile(
                    subjectName: _subjectName(homework, session, item),
                    courseKey: _courseKey(homework, session, item),
                    item: item,
                  ),
                if (remaining > 0) _RemainingLabel(remaining),
              ],
            ),
    );
  }
}

String _subjectName(Homework homework, ActiveUntisSession session, HomeworkItem item) {
  final lesson = homework.lessonsById[item.lessonId];
  final subject = lesson != null ? session.userData.subjects[lesson.subjectId] : null;
  return subject?.name ?? 'Unbekanntes Fach';
}

String? _courseKey(Homework homework, ActiveUntisSession session, HomeworkItem item) {
  final lesson = homework.lessonsById[item.lessonId];
  final keys = lesson?.courseKeys(session.userData) ?? const <String>{};
  return keys.isEmpty ? null : keys.first;
}

class _HomeworkSummaryTile extends StatelessWidget {
  const _HomeworkSummaryTile({required this.subjectName, required this.courseKey, required this.item});

  final String subjectName;
  final String? courseKey;
  final HomeworkItem item;

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = Date(item.endDate).differenceInDays(Date.now());
    final dueLabel = relativeDayLabel(daysUntilDue, item.endDate);
    final dueDateColor = daysUntilDue <= 2 ? Colors.orange : null;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.assignment_outlined, size: 20),
      title: CourseChip(label: subjectName, courseKey: courseKey),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(dueLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: dueDateColor)),
        ],
      ),
      isThreeLine: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeworkScreen()),
      ),
    );
  }
}

class _RemainingLabel extends StatelessWidget {
  const _RemainingLabel(this.remaining);

  final int remaining;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '+$remaining weitere',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}
