import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/homework_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final homework = ref.watch(homeworkOverviewProvider(session));

    final items = [...homework.homeWorks]..sort((a, b) => a.endDate.compareTo(b.endDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Hausaufgaben')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(requestHomeworkProvider(session));
          await ref.read(requestHomeworkProvider(session).future);
        },
        child: items.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Keine Hausaufgaben')),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final lesson = homework.lessonsById[item.lessonId];
                  final subject = lesson != null ? session.userData.subjects[lesson.subjectId] : null;
                  return _HomeworkTile(subjectName: subject?.name ?? 'Unbekanntes Fach', item: item);
                },
              ),
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({required this.subjectName, required this.item});

  final String subjectName;
  final HomeworkItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final daysUntilDue = Date(item.endDate).differenceInDays(Date.now());
    Color? dueDateColor;
    if (!item.completed && daysUntilDue < 0) {
      dueDateColor = colorScheme.error;
    } else if (!item.completed && daysUntilDue <= 2) {
      dueDateColor = Colors.orange;
    }

    return ListTile(
      leading: Icon(
        item.completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: item.completed ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        subjectName,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.text,
            style: TextStyle(
              decoration: item.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          if ((item.remark ?? '').isNotEmpty)
            Text(
              item.remark!,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          Text(
            !item.completed && daysUntilDue < 0
                ? 'Überfällig seit ${item.endDate.day}.${item.endDate.month}.${item.endDate.year}'
                : 'Fällig am ${item.endDate.day}.${item.endDate.month}.${item.endDate.year}',
            style: theme.textTheme.labelSmall?.copyWith(color: dueDateColor),
          ),
        ],
      ),
      isThreeLine: (item.remark ?? '').isNotEmpty,
    );
  }
}
