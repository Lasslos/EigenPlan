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

Exam _exam({
  required int subjectId,
  List<int> klasseIds = const [],
  List<int> teacherIds = const [],
}) => Exam(
  1,
  'Klausur',
  DateTime(2026, 1, 10, 8),
  DateTime(2026, 1, 10, 9),
  subjectId,
  klasseIds,
  const {},
  teacherIds,
  const [],
  'Exam',
  'Text',
);

void main() {
  group('ExamCourseIdentity.courseKeys', () {
    test('unknown subject → empty (unfilterable)', () {
      final userData = _userData();
      final exam = _exam(subjectId: 99);

      expect(exam.courseKeys(userData), isEmpty);
    });

    test('single teacher → one key, subject|teacher', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        teachers: const {7: Teacher('MusL', 'Mustermann', 'Lisa', true)},
      );
      final exam = _exam(subjectId: 15, teacherIds: [7]);

      expect(exam.courseKeys(userData), {'D|MusL'});
    });

    test('multiple teachers → one candidate key per teacher', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        teachers: const {
          7: Teacher('MusL', 'Mustermann', 'Lisa', true),
          8: Teacher('SchmJ', 'Schmidt', 'Jan', true),
        },
      );
      final exam = _exam(subjectId: 15, teacherIds: [7, 8]);

      expect(exam.courseKeys(userData), {'D|MusL', 'D|SchmJ'});
    });

    test('no teachers, falls back to classes', () {
      final userData = _userData(
        subjects: const {15: Subject('D', 'Deutsch', true)},
        klassen: {1517: _klasse('5d')},
      );
      final exam = _exam(subjectId: 15, klasseIds: [1517]);

      expect(exam.courseKeys(userData), {'D|5d'});
    });

    test('no teachers and no classes → single key with empty differentiator', () {
      final userData = _userData(subjects: const {15: Subject('D', 'Deutsch', true)});
      final exam = _exam(subjectId: 15);

      expect(exam.courseKeys(userData), {'D|'});
    });
  });
}
