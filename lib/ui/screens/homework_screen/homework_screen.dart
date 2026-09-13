import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/homework_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';
import 'package:your_schedule/util/homework_grouping.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  bool _showOlder = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final homework = ref.watch(homeworkOverviewProvider(session));

    final split = splitHomeworkByDueDate(homework.homeWorks);

    Widget tileFor(HomeworkItem item) {
      final lesson = homework.lessonsById[item.lessonId];
      final subject = lesson != null ? session.userData.subjects[lesson.subjectId] : null;
      return _HomeworkTile(subjectName: subject?.name ?? 'Unbekanntes Fach', item: item);
    }

    void addGroup(List<Widget> target, List<HomeworkItem> items) {
      for (var i = 0; i < items.length; i++) {
        if (i > 0) {
          target.add(const Divider(height: 1, indent: 16));
        }
        target.add(tileFor(items[i]));
      }
    }

    final children = <Widget>[];
    if (split.upcoming.isEmpty && split.older.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Keine Hausaufgaben')),
        ),
      );
    } else {
      if (split.upcoming.isEmpty) {
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Keine anstehenden Hausaufgaben'),
          ),
        );
      } else {
        addGroup(children, split.upcoming);
      }
      if (split.older.isNotEmpty) {
        children.add(
          _OlderHomeworkToggle(
            count: split.older.length,
            expanded: _showOlder,
            onToggle: () => setState(() => _showOlder = !_showOlder),
          ),
        );
        if (_showOlder) {
          addGroup(children, split.older);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hausaufgaben')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(requestHomeworkProvider(session));
          await ref.read(requestHomeworkProvider(session).future);
        },
        child: ListView(children: children),
      ),
    );
  }
}

class _OlderHomeworkToggle extends StatelessWidget {
  const _OlderHomeworkToggle({
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      title: Text(
        expanded ? 'Ältere Hausaufgaben ausblenden' : 'Zeige ältere Hausaufgaben ($count)',
      ),
      onTap: onToggle,
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
