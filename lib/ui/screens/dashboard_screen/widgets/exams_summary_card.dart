import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/exams_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/dashboard_summary_card.dart';
import 'package:your_schedule/ui/screens/exams_screen/exams_screen.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/week.dart';

const _windowDays = 14;
const _maxItemsShown = 4;

/// Weeks needed to safely cover a 14-day-forward window — since weeks here start
/// Saturday, "today" can be as early as the first day of `Week.now()`, pushing the
/// window into `Week.relative(2)`.
const _weeksToWatch = 3;

/// Exams within the next [_windowDays] days, capped to [_maxItemsShown] —
/// "Alle anzeigen" is the only remaining path to [ExamsScreen], so it's always shown,
/// even when this card's own filtered list is empty.
class ExamsSummaryCard extends ConsumerWidget {
  const ExamsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final today = Date.now();

    final exams = <Exam>[
      for (var i = 0; i < _weeksToWatch; i++)
        for (final dayExams in ref.watch(examsProvider(session, Week.relative(i))).values) ...dayExams,
    ]
      ..removeWhere((exam) {
        final daysUntil = Date(exam.startDateTime).differenceInDays(today);
        return daysUntil < 0 || daysUntil > _windowDays;
      })
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    final displayed = exams.take(_maxItemsShown).toList();
    final remaining = exams.length - displayed.length;

    return DashboardSummaryCard(
      title: 'Prüfungen',
      onShowMore: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExamsScreen()),
      ),
      child: exams.isEmpty
          ? const Text('Keine Prüfungen in den nächsten 14 Tagen.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final exam in displayed) _ExamSummaryTile(exam: exam, userData: session.userData),
                if (remaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+$remaining weitere', style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
    );
  }
}

class _ExamSummaryTile extends StatelessWidget {
  const _ExamSummaryTile({required this.exam, required this.userData});

  final Exam exam;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    final subject = userData.subjects[exam.subjectId];
    final dateLabel = intl.DateFormat('EEE, dd.MM.', 'de').format(exam.startDateTime);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_calendar_outlined, size: 20),
      title: Text(subject?.name ?? exam.name),
      subtitle: Text(dateLabel),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExamsScreen()),
      ),
    );
  }
}
