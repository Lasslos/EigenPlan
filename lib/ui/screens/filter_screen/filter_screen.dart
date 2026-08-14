import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/timetable_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/utils.dart';

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

  List<int> periods = [];

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
      selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData),
      (_, next) {
        setState(() {
          _initPeriods();
        });
      },
    );

    var session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    for (var i = -2; i < 3; i++) {
      ref.listen(
        timeTableProvider(session, Week.relative(i)),
        (_, next) {
          setState(() {
            _initPeriods();
          });
        },
      );
    }

    // Start of real build logic

    var filters = ref.watch(filtersProvider);
    var timeTableWeeks = [for (var i = -2; i < 3; i++) ref.watch(timeTableProvider(session, Week.relative(i)))];
    var timeTablePeriods = _getRelevantTimeTablePeriods(timeTableWeeks);

    var subjects = session.userData.subjects;
    var teachers = session.userData.teachers;
    var rooms = session.userData.rooms;

    final gridChildren = periods.map<Widget>(
      (e) {
        TimeTablePeriod examplePeriod = timeTablePeriods.firstWhere((element) => e == element.subject?.id);
        Subject? subject = subjects[e];
        Teacher? teacher = teachers[examplePeriod.teacher?.id];
        Room? room = rooms[examplePeriod.room?.id];

        return Padding(
          key: ValueKey(e),
          padding: const EdgeInsets.all(4.0),
          child: Selectable(
            selected: filters.contains(e),
            onChanged: (bool value) {
              if (value) {
                ref.read(filtersProvider.notifier).add(e);
              } else {
                ref.read(filtersProvider.notifier).remove(e);
              }
            },
            child: Center(
              child: FilterGridTile(
                subject: subject?.name ?? 'Kein Fach',
                teacher: teacher?.shortName ?? 'Kein Lehrer',
                room: room?.name ?? 'Kein Raum',
              ),
            ),
          ),
        );
      },
    ).toList();

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
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: !showSearch
              ? const Row(
                  children: [
                    Text('Deine Kurse'),
                    Spacer(),
                  ],
                )
              : Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.onSurface
                        .withAlpha(30),
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
                            _filterPeriods(periods, filters, subjects, teachers, rooms, timeTablePeriods);
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
                          icon: const Icon(
                            Icons.close,
                          ),
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
          if (!showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  showSearch = true;
                });
              },
            ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 4,
        children: gridChildren,
      ),
    );
  }

  void _initPeriods() {
    var session = ref.read(selectedUntisSessionProvider) as ActiveUntisSession;
    var userData = session.userData;
    periods = userData.subjects.keys.toList();

    var filters = ref.read(filtersProvider);
    var subjects = userData.subjects;
    var teachers = userData.teachers;
    var rooms = userData.rooms;
    var timeTableWeeks = [for (var i = -2; i < 3; i++) ref.read(timeTableProvider(session, Week.relative(i)))];
    var timeTablePeriods = _getRelevantTimeTablePeriods(timeTableWeeks);

    _sortPeriods(periods, filters, subjects);
    _filterPeriods(periods, filters, subjects, teachers, rooms, timeTablePeriods);
  }

  List<TimeTablePeriod> _getRelevantTimeTablePeriods(List<TimeTableWeek> timeTableWeeks) {
    return timeTableWeeks.fold<List<TimeTablePeriod>>(
      [],
      (list, element) => list
        ..addAll(
          element.values.fold<List<TimeTablePeriod>>(
            [],
            (list, element) => list..addAll(element),
          ),
        ),
    );
  }

  void _sortPeriods(List<int> periods, Set<int> filters, Map<int, Subject> subjects) {
    periods.sort((a, b) {
      if (filters.contains(a) && !filters.contains(b)) {
        return -1;
      } else if (!filters.contains(a) && filters.contains(b)) {
        return 1;
      } else {
        return subjects[a]?.name.compareTo(subjects[b]?.name ?? '') ?? 0;
      }
    });
  }

  void _filterPeriods(
    List<int> periods,
    Set<int> filters,
    Map<int, Subject> subjects,
    Map<int, Teacher> teachers,
    Map<int, Room> rooms,
    List<TimeTablePeriod> timeTable,
  ) {
    // Filter every non-valid class
    periods
      ..retainWhere((e) {
        var examplePeriod = timeTable.firstWhereOrNull((element) => element.subject?.id == e);
        if (examplePeriod == null) {
        return false;
      }
      var subjectId = examplePeriod.subject?.id;
      var teacherId = examplePeriod.teacher?.id;
      var roomId = examplePeriod.room?.id;
        if (subjectId != null && !subjects.containsKey(subjectId) ||
            teacherId != null && !teachers.containsKey(teacherId) ||
            roomId != null && !rooms.containsKey(roomId)) {
          return false;
      }

        return true;
      })

      // Filter by search query
      ..retainWhere((e) {
        var examplePeriod = timeTable.firstWhereOrNull((element) => element.subject?.id == e);
      var subject = subjects[e];
      var teacher = teachers[examplePeriod?.teacher?.id];
      var room = rooms[examplePeriod?.room?.id];

      var accept = false;
      if (subject != null) {
        accept = subject.name.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
        accept = subject.longName.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
      }
      if (teacher != null) {
        accept = teacher.firstName.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
        accept = teacher.lastName.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
        accept = teacher.shortName.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
      }
      if (room != null) {
        accept = room.name.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
        accept = room.longName.toLowerCase().contains(searchQuery.toLowerCase()) || accept;
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(30),
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
