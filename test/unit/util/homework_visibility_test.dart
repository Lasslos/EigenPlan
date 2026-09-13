import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/homework_visibility.dart';

UserData _userData({
  Map<int, Subject> subjects = const {},
  Map<int, Teacher> teachers = const {},
}) => UserData(
  0,
  const {},
  const {},
  const {},
  subjects,
  teachers,
  const [],
  'STUDENT',
  1,
  'Test User',
  'Test School',
);

HomeworkItem _item(int id, int lessonId) => HomeworkItem(
  id: id,
  lessonId: lessonId,
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 10),
  text: 'Aufgabe $id',
  completed: false,
);

void main() {
  group('filterHomeworkByVisibility', () {
    final userData = _userData(
      subjects: const {15: Subject('D', 'Deutsch', true)},
      teachers: const {
        7: Teacher('MusL', 'Mustermann', 'Lisa', true),
        8: Teacher('SchmJ', 'Schmidt', 'Jan', true),
      },
    );

    test('empty overrides → returns the same homework unchanged', () {
      final homework = Homework(
        [_item(1, 100)],
        const {100: HomeworkLesson(id: 100, subjectId: 15, klassenIds: [], teacherIds: [7])},
      );

      expect(filterHomeworkByVisibility(homework, userData, const {}), same(homework));
    });

    test('explicit false for the only candidate → item dropped', () {
      final homework = Homework(
        [_item(1, 100)],
        const {100: HomeworkLesson(id: 100, subjectId: 15, klassenIds: [], teacherIds: [7])},
      );

      final filtered = filterHomeworkByVisibility(homework, userData, const {'D|MusL': false});

      expect(filtered.homeWorks, isEmpty);
    });

    test('one of several candidates hidden, another visible → item kept', () {
      final homework = Homework(
        [_item(1, 100)],
        const {100: HomeworkLesson(id: 100, subjectId: 15, klassenIds: [], teacherIds: [7, 8])},
      );

      final filtered = filterHomeworkByVisibility(homework, userData, const {'D|MusL': false});

      expect(filtered.homeWorks, hasLength(1));
    });

    test('all candidates explicitly hidden → item dropped', () {
      final homework = Homework(
        [_item(1, 100)],
        const {100: HomeworkLesson(id: 100, subjectId: 15, klassenIds: [], teacherIds: [7, 8])},
      );

      final filtered = filterHomeworkByVisibility(
        homework,
        userData,
        const {'D|MusL': false, 'D|SchmJ': false},
      );

      expect(filtered.homeWorks, isEmpty);
    });

    test('missing lesson info → item kept (unfilterable)', () {
      final homework = Homework([_item(1, 999)], const {});

      final filtered = filterHomeworkByVisibility(homework, userData, const {'D|MusL': false});

      expect(filtered.homeWorks, hasLength(1));
    });
  });
}
