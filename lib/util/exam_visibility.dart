import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/util/date.dart';

/// Whether [exam] is behind us: the calendar day it falls on has passed.
///
/// Exams stay listed for the whole of their day, written or not — at 14:00 this morning's
/// maths exam is still the thing that happened today, and a countdown that says "Heute"
/// shouldn't blink out mid-morning. Both the dashboard's `ExamsSummaryCard` and
/// `ExamsScreen` filter through this one predicate; when they each had their own (one by
/// day, one by `endDateTime`) the same exam showed up on one and not the other.
///
/// Measured against the exam's *end*, so an exam spanning several days survives until its
/// final day is over rather than dropping off after the first.
bool isExamPast(Exam exam, Date today) => Date(exam.endDateTime).isBefore(today);
