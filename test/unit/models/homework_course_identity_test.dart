import 'package:flutter_test/flutter_test.dart';
import 'package:your_schedule/core/untis.dart';

UserData _userData({
  Map<int, Subject> subjects = const {},
  Map<int, Teacher> teachers = const {},
  Map<int, Klasse> klassen = const {},
}) => UserData(
  0,
  const {},
  klassen,
  const {},
  subjects,
  teachers,
  const [],
  'STUDENT',
  1,
  'Test User',
  'Test School',
);

Klasse _klasse(String name) => Klasse(name, name, DateTime(2026), DateTime(2027), true, true);

void main() {
  group('HomeworkLessonCourseIdentity.courseKeys', () {
    test('unknown subject → empty (unfilterable)', () {
      final userData = _userData();
      const lesson = HomeworkLesson(id: 1, subjectId: 99, klassenIds: [], teacherIds: []);

      expect(lesson.courseKeys(userData), isEmpty);
    });

    test('single teacher → one key, subject|teacher', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        teachers: const {7: Teacher('MusL', 'Mustermann', 'Lisa', true)},
      );
      const lesson = HomeworkLesson(id: 1, subjectId: 15, klassenIds: [], teacherIds: [7]);

      expect(lesson.courseKeys(userData), {'D|MusL'});
    });

    test('multiple teachers → one candidate key per teacher', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        teachers: const {
          7: Teacher('MusL', 'Mustermann', 'Lisa', true),
          8: Teacher('SchmJ', 'Schmidt', 'Jan', true),
        },
      );
      const lesson = HomeworkLesson(id: 1, subjectId: 15, klassenIds: [], teacherIds: [7, 8]);

      expect(lesson.courseKeys(userData), {'D|MusL', 'D|SchmJ'});
    });

    test('no teachers, falls back to classes', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        klassen: {1517: _klasse('5d')},
      );
      const lesson = HomeworkLesson(id: 1, subjectId: 15, klassenIds: [1517], teacherIds: []);

      expect(lesson.courseKeys(userData), {'D|5d'});
    });

    test('no teachers and no classes → single key with empty differentiator', () {
      final userData = _userData(subjects: const {15: Subject('D', 'Deutsch', true)});
      const lesson = HomeworkLesson(id: 1, subjectId: 15, klassenIds: [], teacherIds: []);

      expect(lesson.courseKeys(userData), {'D|'});
    });

    test('unknown teacher id falls back to empty differentiator, never dropped', () {
      final userData = _userData(subjects: const {15: Subject('D', 'Deutsch', true)});
      const lesson = HomeworkLesson(id: 1, subjectId: 15, klassenIds: [], teacherIds: [404]);

      expect(lesson.courseKeys(userData), {'D|'});
    });
  });
}
