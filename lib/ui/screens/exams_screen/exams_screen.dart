import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/clock_provider.dart';
import 'package:your_schedule/core/provider/exams_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/ui/shared/course_chip.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/exam_visibility.dart';
import 'package:your_schedule/util/week.dart';

const _initialWeeksShown = 6;
const _weeksPerLoadMore = 4;

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  int _weeksShown = _initialWeeksShown;

  List<Week> _weeks(Date today) => [for (var i = 0; i < _weeksShown; i++) Week.relativeTo(today, i)];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    // An exam drops off this list once its day is over, so the list has to follow the
    // clock rather than whenever the screen last happened to rebuild — [todayProvider]
    // notifies at midnight.
    final today = ref.watch(todayProvider);
    final weeks = _weeks(today);

    final exams = <Exam>[
      for (final week in weeks)
        for (final dayExams in ref.watch(examsProvider(session, week)).values) ...dayExams,
    ]
      ..removeWhere((exam) => isExamPast(exam, today))
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Prüfungen')),
      body: RefreshIndicator(
        onRefresh: () async {
          for (final week in weeks) {
            ref.invalidate(requestExamsProvider(session, week));
          }
          await Future.wait([
            for (final week in weeks) ref.read(requestExamsProvider(session, week).future),
          ]);
        },
        child: exams.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Keine anstehenden Prüfungen')),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: exams.length + 1,
                itemBuilder: (context, index) {
                  if (index == exams.length) {
                    return ListTile(
                      title: const Center(child: Text('Weitere Wochen laden')),
                      onTap: () => setState(() => _weeksShown += _weeksPerLoadMore),
                    );
                  }
                  final exam = exams[index];
                  final showDayHeader = index == 0 ||
                      !_isSameDay(exams[index - 1].startDateTime, exam.startDateTime);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDayHeader)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text(
                            relativeDayLabel(
                              Date(exam.startDateTime).differenceInDays(today),
                              exam.startDateTime,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        )
                      else
                        const Divider(height: 1, indent: 16),
                      _ExamTile(exam: exam, userData: session.userData),
                    ],
                  );
                },
              ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ExamTile extends StatelessWidget {
  const _ExamTile({required this.exam, required this.userData});

  final Exam exam;
  final UserData userData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = userData.subjects[exam.subjectId];
    final rooms = exam.roomIds.map((id) => userData.rooms[id]?.name ?? '?').join(', ');
    final teachers = exam.teacherIds.map((id) => userData.teachers[id]?.shortName ?? '?').join(', ');
    final timeRange =
        '${intl.DateFormat('HH:mm').format(exam.startDateTime)}–${intl.DateFormat('HH:mm').format(exam.endDateTime)}';
    final keys = exam.courseKeys(userData);

    return ListTile(
      title: CourseChip(
        label: subject?.name ?? exam.name,
        courseKey: keys.isEmpty ? null : keys.first,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exam.text.isNotEmpty ? exam.text : exam.name),
          Text(
            [
              timeRange,
              if (rooms.isNotEmpty) rooms,
              if (teachers.isNotEmpty) teachers,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      trailing: exam.examType != null ? Chip(label: Text(exam.examType!)) : null,
      isThreeLine: true,
    );
  }
}
