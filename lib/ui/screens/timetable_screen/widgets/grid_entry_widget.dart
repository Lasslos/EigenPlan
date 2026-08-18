import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/selected_timetable_resource_provider.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/custom_subject_color/custom_subject_color.dart';
import 'package:your_schedule/util/logger.dart';

const _statusDisplayNames = {
  'REGULAR': 'Regulär',
  'CHANGED': 'Geändert',
  'CANCELLED': 'Ausfall',
};

/// The [GridEntryPositionItem] carrying the primary subject-like text for [entry] —
/// `SUBJECT` normally, or `INFO` for non-teaching entries (e.g. a day-long `EVENT`).
GridEntryPositionItem? _subjectSlot(GridEntry entry) =>
    entry.positionOfType('SUBJECT') ?? entry.positionOfType('INFO');

/// The secondary text — `TEACHER` normally, falling back to `CLASS` for a
/// `resourceType: TEACHER` timetable, where there usually isn't a second teacher to
/// show but the class being taught is exactly what you want to see instead.
GridEntryPositionItem? _teacherSlot(GridEntry entry) =>
    entry.positionOfType('TEACHER') ?? entry.positionOfType('CLASS');

GridEntryPositionItem? _roomSlot(GridEntry entry) =>
    entry.positionOfType('ROOM');

String _text(GridEntryPositionElement? element, {required bool short}) {
  if (element == null) {
    return '';
  }
  return (short ? element.shortName : element.longName) ??
      element.displayName ??
      '';
}

class GridEntryWidget extends ConsumerWidget {
  const GridEntryWidget({
    required this.entry,
    required this.fontSize,
    super.key,
  });

  final double fontSize;
  final GridEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var courseKey = entry.courseKey;

    CustomSubjectColor statusColor;
    bool isRegularStatusColor = false;

    if (entry.isExam) {
      statusColor = CustomSubjectColor.examColor;
    } else if (entry.isCancelled) {
      statusColor = CustomSubjectColor.cancelledColor;
    } else if (entry.isChanged || entry.hasSubstitution) {
      statusColor = CustomSubjectColor.irregularColor;
    } else if (entry.status == 'REGULAR') {
      isRegularStatusColor = true;
      statusColor =
          ref.watch(customSubjectColorsProvider)[courseKey] ??
          CustomSubjectColor.regularColor;
    } else {
      statusColor = CustomSubjectColor.emptyColor;
    }

    var subjectSlot = _subjectSlot(entry);
    var teacherSlot = _teacherSlot(entry);
    var roomSlot = _roomSlot(entry);

    Color textColor = entry.isCancelled
        ? Theme.of(context).textTheme.bodyLarge!.color!
        : statusColor.textColor;

    return Card(
      margin: const EdgeInsets.all(2),
      color: entry.isCancelled
          ? Theme.of(context).cardColor
          : statusColor.color,
      shape: entry.isCancelled
          ? RoundedRectangleBorder(
              side: BorderSide(color: statusColor.color, width: 3),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GridEntryDetailsView(
                entry: entry,
                statusColor: isRegularStatusColor ? null : statusColor,
              ),
              fullscreenDialog: true,
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool useShort =
                constraints.maxWidth < 100 ||
                subjectSlot?.removed != null ||
                teacherSlot?.removed != null ||
                roomSlot?.removed != null;

            String subjectText = _text(subjectSlot?.current, short: useShort);
            if (subjectText.isEmpty) {
              subjectText = entry.lessonText ?? '';
            }
            String teacherText = _text(teacherSlot?.current, short: useShort);
            String roomText = _text(roomSlot?.current, short: useShort);

            String orgSubjectText = _text(subjectSlot?.removed, short: true);
            String orgTeacherText = _text(teacherSlot?.removed, short: true);
            String orgRoomText = _text(roomSlot?.removed, short: true);

            Widget lineOf(String orgText, String text) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: orgText,
                    style: const TextStyle(
                      color: Colors.white60,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  if (orgText.isNotEmpty && text.isNotEmpty)
                    const TextSpan(text: ' '),
                  TextSpan(text: text),
                ],
                style: TextStyle(fontSize: fontSize, color: textColor),
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (subjectText.isNotEmpty || orgSubjectText.isNotEmpty)
                  Flexible(child: lineOf(orgSubjectText, subjectText)),
                if (teacherText.isNotEmpty || orgTeacherText.isNotEmpty)
                  Flexible(child: lineOf(orgTeacherText, teacherText)),
                if (roomText.isNotEmpty || orgRoomText.isNotEmpty)
                  Flexible(child: lineOf(orgRoomText, roomText)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GridEntryDetailsView extends ConsumerWidget {
  final GridEntry entry;
  final CustomSubjectColor? statusColor;

  const GridEntryDetailsView({
    required this.entry,
    required this.statusColor,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    var resource = ref.watch(effectiveTimetableResourceProvider(session));
    var courseKey = entry.courseKey;
    var customSubjectColor =
        ref.watch(customSubjectColorsProvider)[courseKey] ??
        CustomSubjectColor.regularColor;

    var subjectSlot = _subjectSlot(entry);
    var teacherSlot = _teacherSlot(entry);
    var roomSlot = _roomSlot(entry);

    String headline = _text(subjectSlot?.current, short: false);
    if (headline.isEmpty) {
      headline = entry.lessonText ?? '';
    }
    String orgHeadline = _text(subjectSlot?.removed, short: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: statusColor?.color ?? customSubjectColor.color,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: statusColor?.textColor ?? customSubjectColor.textColor,
        ),
        title: Text(
          'Stundendetails',
          style: TextStyle(
            color: statusColor?.textColor ?? customSubjectColor.textColor,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 50,
                  color: statusColor?.color ?? customSubjectColor.color,
                ),
                ListTile(
                  title: Text.rich(
                    TextSpan(
                      children: [
                        if (orgHeadline.isNotEmpty && orgHeadline != headline)
                          TextSpan(
                            text: orgHeadline,
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (orgHeadline.isNotEmpty && orgHeadline != headline)
                          const TextSpan(text: ' '),
                        TextSpan(text: headline),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    "${intl.DateFormat("dd. MMM HH:mm").format(entry.duration.start)}-${intl.DateFormat("HH:mm").format(entry.duration.end)}",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          if (subjectSlot?.current?.shortName != null &&
              subjectSlot!.current!.shortName != subjectSlot.current!.longName)
            ListTile(
              leading: const Icon(Icons.subject),
              title: const Text('Kurs'),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    if (subjectSlot.removed != null)
                      TextSpan(
                        text: subjectSlot.removed!.shortName,
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (subjectSlot.removed != null) const TextSpan(text: ' '),
                    TextSpan(text: subjectSlot.current!.shortName),
                  ],
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Lehrer'),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  if (teacherSlot?.removed != null)
                    TextSpan(
                      text: _text(
                        teacherSlot!.removed,
                        short: false,
                      ).let((s) => s.isEmpty ? 'Kein Lehrer' : s),
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (teacherSlot?.removed != null) const TextSpan(text: ' '),
                  TextSpan(
                    text: _text(
                      teacherSlot?.current,
                      short: false,
                    ).let((s) => s.isEmpty ? 'Kein Lehrer' : s),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Raum'),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  if (roomSlot?.removed != null)
                    TextSpan(
                      text: _text(
                        roomSlot!.removed,
                        short: false,
                      ).let((s) => s.isEmpty ? 'Kein Raum' : s),
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (roomSlot?.removed != null) const TextSpan(text: ' '),
                  TextSpan(
                    text: _text(
                      roomSlot?.current,
                      short: false,
                    ).let((s) => s.isEmpty ? 'Kein Raum' : s),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Status'),
            subtitle: Text(
              [
                _statusDisplayNames[entry.status] ?? entry.status,
                if (entry.statusDetail != null) entry.statusDetail!,
              ].join(', '),
            ),
          ),
          if ((entry.lessonInfo ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(entry.lessonInfo!),
            ),
          if ((entry.lessonText ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(entry.lessonText!),
            ),
          if ((entry.substitutionText ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: Text(entry.substitutionText!),
            ),
          if (entry.icons.contains('HOMEWORK') || entry.icons.contains('NOTES'))
            _CalendarEntryDetailSection(entry: entry, session: session),
          const Divider(thickness: 1),
          if (courseKey != null)
            ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: customSubjectColor.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              title: const Text('Farbe ändern'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Farbe ändern'),
                    content: MaterialColorPicker(
                      onColorChange: (color) {
                        Color textColor = color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white;
                        ref
                            .read(customSubjectColorsProvider.notifier)
                            .add(
                              CustomSubjectColor(courseKey, color, textColor),
                            );
                      },
                      selectedColor: customSubjectColor.color,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(customSubjectColorsProvider.notifier)
                              .remove(courseKey);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Zurücksetzen'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Ok'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (courseKey != null && resource != null)
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.red),
              title: const Text(
                'Kurs ausblenden',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                ref
                    .read(filtersProvider.notifier)
                    .setOverride(resource.storageKey, courseKey, false);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

/// On-demand "tap a period" enrichment via `calendar-entry/detail` — notes and
/// per-period homework not available from [GridEntry] itself. Best-effort: silently
/// omits itself (no error UI) if the resource type can't be resolved or the request
/// fails, since this is an enrichment on top of an already-complete details dialog,
/// not something the user is blocked without.
class _CalendarEntryDetailSection extends ConsumerWidget {
  const _CalendarEntryDetailSection({
    required this.entry,
    required this.session,
  });

  final GridEntry entry;
  final ActiveUntisSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elementType = elementTypeForResourceType(session.userData.type);
    if (elementType == null) {
      return const SizedBox.shrink();
    }

    final detail = ref.watch(
      requestCalendarEntryDetailProvider(
        session,
        elementType,
        session.userData.id,
        entry.duration.start,
        entry.duration.end,
      ),
    );

    return detail.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        final calendarEntry = entries.first;
        return Column(
          children: [
            if ((calendarEntry.notesAll ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(calendarEntry.notesAll!),
              ),
            if ((calendarEntry.notesStaff ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(calendarEntry.notesStaff!),
              ),
            for (final hw in calendarEntry.homeworks)
              ListTile(
                leading: Icon(
                  hw.completed
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                title: Text(
                  hw.text,
                  style: TextStyle(
                    decoration: hw.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: (hw.remark ?? '').isNotEmpty
                    ? Text(hw.remark!)
                    : null,
              ),
          ],
        );
      },
      error: (error, stackTrace) {
        logRequestError(
          'Error while requesting calendar entry detail',
          error,
          stackTrace,
        );
        return const SizedBox.shrink();
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
    );
  }
}
