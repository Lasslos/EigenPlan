import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

/// Course-visibility picker for whichever timetable is currently shown on the home
/// screen (`effectiveTimetableResourceProvider`). Every course is visible by
/// default; toggling one here writes an override to `filtersProvider`, scoped to
/// this one resource only — switching to a different timetable via the home screen's
/// "Stundenplan wechseln" picker and coming back here shows/edits *that* timetable's
/// own overrides instead.
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late FocusNode searchFocusNode;
  late TextEditingController searchController;
  bool showSearch = false;
  String searchQuery = '';

  List<String> periods = [];

  @override
  void initState() {
    super.initState();
    searchFocusNode = FocusNode();
    searchController = TextEditingController();

    _initPeriods();
  }

  @override
  Widget build(BuildContext context) {
    // We don't want to rebuild the periods in certain scenarios, such as the search query being appended.
    // Since build must be called regardless, we can't compute the list in here. To still apply updates from other providers, we listen and rebuild in case.

    ref.listen(
      selectedUntisSessionProvider.select(
        (value) => (value as ActiveUntisSession).userData,
      ),
      (_, next) {
        setState(() {
          _initPeriods();
        });
      },
    );

    var session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    var resource = ref.watch(effectiveTimetableResourceProvider(session));
    if (resource != null) {
      for (var i = -2; i < 3; i++) {
        ref.listen(timeTableProvider(session, Week.relative(i), resource), (
          _,
          next,
        ) {
          setState(() {
            _initPeriods();
          });
        });
      }
    }

    // Start of real build logic

    var overrides = resource == null
        ? const <String, bool>{}
        : ref.watch(courseOverridesForResourceProvider(resource));
    var resourceKey = resource?.storageKey;
    var selected = {
      for (final p in periods)
        if (overrides[p] ?? true) p,
    };

    var timeTableWeeks = resource == null
        ? <TimeTableWeek>[]
        : [
            for (var i = -2; i < 3; i++)
              ref.watch(timeTableProvider(session, Week.relative(i), resource)),
          ];
    var gridEntries = _getRelevantGridEntries(timeTableWeeks);

    final gridChildren = periods.map<Widget>((e) {
      GridEntry exampleEntry = gridEntries.firstWhere(
        (entry) => e == entry.courseKey,
      );
      var subjectText = exampleEntry
          .positionOfType('SUBJECT')
          ?.current
          ?.shortName;
      var teacherText = exampleEntry
          .positionOfType('TEACHER')
          ?.current
          ?.shortName;
      var roomText = exampleEntry.positionOfType('ROOM')?.current?.shortName;

      return Padding(
        key: ValueKey(e),
        padding: const EdgeInsets.all(4.0),
        child: Selectable(
          selected: selected.contains(e),
          onChanged: (bool value) {
            ref
                .read(filtersProvider.notifier)
                .setOverride(resourceKey!, e, value);
          },
          child: Center(
            child: FilterGridTile(
              subject: subjectText ?? 'Kein Fach',
              teacher: teacherText ?? 'Kein Lehrer',
              room: roomText ?? 'Kein Raum',
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: showSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showSearch = false;
                    searchQuery = '';
                    searchFocusNode.unfocus();
                    searchController.clear();
                  });
                },
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: !showSearch
              ? const Row(children: [Text('Deine Kurse'), Spacer()])
              : Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(30),
                  ),
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          if (!value.startsWith(searchQuery)) {
                            searchQuery = value;
                            _initPeriods();
                          } else {
                            searchQuery = value;
                            _filterPeriods(periods, gridEntries);
                          }
                        });
                      },
                      controller: searchController,
                      focusNode: searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      autofocus: true,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          iconSize: 18,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = '';
                              _initPeriods();
                            });
                          },
                        ),
                        hintText: 'Suchen',
                      ),
                    ),
                  ),
                ),
        ),
        actions: [
          if (!showSearch && resourceKey != null) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Alle auswählen',
              onPressed: () {
                ref
                    .read(filtersProvider.notifier)
                    .setOverridesForResource(resourceKey, {
                      for (final p in periods) p: true,
                    });
              },
            ),
            IconButton(
              icon: const Icon(Icons.deselect),
              tooltip: 'Alle abwählen',
              onPressed: () {
                ref
                    .read(filtersProvider.notifier)
                    .setOverridesForResource(resourceKey, {
                      for (final p in periods) p: false,
                    });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  showSearch = true;
                });
              },
            ),
          ],
        ],
      ),
      body: GridView.count(crossAxisCount: 4, children: gridChildren),
    );
  }

  void _initPeriods() {
    var session = ref.read(selectedUntisSessionProvider) as ActiveUntisSession;
    var resource = ref.read(effectiveTimetableResourceProvider(session));
    var overrides = resource == null
        ? const <String, bool>{}
        : ref.read(courseOverridesForResourceProvider(resource));
    var timeTableWeeks = resource == null
        ? <TimeTableWeek>[]
        : [
            for (var i = -2; i < 3; i++)
              ref.read(timeTableProvider(session, Week.relative(i), resource)),
          ];
    var gridEntries = _getRelevantGridEntries(timeTableWeeks);

    periods = {
      for (final e in gridEntries)
        if (e.courseKey != null) e.courseKey!,
    }.toList();

    var selected = {
      for (final p in periods)
        if (overrides[p] ?? true) p,
    };

    _sortPeriods(periods, selected, gridEntries);
    _filterPeriods(periods, gridEntries);
  }

  List<GridEntry> _getRelevantGridEntries(List<TimeTableWeek> timeTableWeeks) {
    return [
      for (var week in timeTableWeeks)
        for (var day in week.values) ...day.gridEntries,
    ];
  }

  void _sortPeriods(
    List<String> periods,
    Set<String> selected,
    List<GridEntry> gridEntries,
  ) {
    periods.sort((a, b) {
      if (selected.contains(a) && !selected.contains(b)) {
        return -1;
      } else if (!selected.contains(a) && selected.contains(b)) {
        return 1;
      } else {
        return a.compareTo(b);
      }
    });
  }

  void _filterPeriods(List<String> periods, List<GridEntry> gridEntries) {
    // Filter by search query
    periods.retainWhere((e) {
      var exampleEntry = gridEntries.firstWhereOrNull(
        (entry) => entry.courseKey == e,
      );
      var subjectName = exampleEntry?.positionOfType('SUBJECT')?.current;
      var teacherName = exampleEntry?.positionOfType('TEACHER')?.current;
      var roomName = exampleEntry?.positionOfType('ROOM')?.current;

      var accept = false;
      if (subjectName != null) {
        accept =
            (subjectName.shortName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
        accept =
            (subjectName.longName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
      }
      if (teacherName != null) {
        accept =
            (teacherName.shortName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
        accept =
            (teacherName.longName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
      }
      if (roomName != null) {
        accept =
            (roomName.shortName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
        accept =
            (roomName.longName ?? '').toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            accept;
      }
      return accept;
    });
  }
}

class Selectable extends StatelessWidget {
  final Function(bool value) onChanged;
  final bool selected;
  final Widget child;

  const Selectable({
    required this.onChanged,
    required this.selected,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!selected);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.onSurface.withAlpha(30)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              scale: selected ? 0.75 : 1,
              child: child,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 150),
                  crossFadeState: selected
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  secondChild: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(30),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterGridTile extends StatelessWidget {
  const FilterGridTile({
    required this.subject,
    required this.teacher,
    required this.room,
    super.key,
  });

  final String subject;
  final String teacher;
  final String room;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: GridTile(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                subject,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
              Text(
                teacher,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
              Text(
                room,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
