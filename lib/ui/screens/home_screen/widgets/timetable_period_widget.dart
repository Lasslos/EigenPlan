import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:your_schedule/core/provider/custom_subject_colors.dart';
import 'package:your_schedule/core/provider/filters.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/custom_subject_color/custom_subject_color.dart';

class TimeTablePeriodWidget extends ConsumerWidget {
  const TimeTablePeriodWidget({
    required this.period,
    required this.fontSize,
    super.key,
  });

  final double fontSize;
  final TimeTablePeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    UserData userData = ref.watch(selectedUntisSessionProvider.select((value) => (value as ActiveUntisSession).userData));

    CustomSubjectColor statusColor;
    bool isRegularStatusColor = false;
    List<TimeTablePeriodStatus> periodStatuses = period.periodStatus;

    if (periodStatuses.contains(TimeTablePeriodStatus.exam)) {
      statusColor = CustomSubjectColor.examColor;
    } else if (periodStatuses.contains(TimeTablePeriodStatus.cancelled)) {
      statusColor = CustomSubjectColor.cancelledColor;
    } else if (periodStatuses.contains(TimeTablePeriodStatus.irregular) ||
        (period.subject?.let((self) => self.id != self.orgId) ?? false) ||
        (period.room?.let((self) => self.id != self.orgId) ?? false) ||
        (period.teacher?.let((self) => self.id != self.orgId) ?? false)) {
      statusColor = CustomSubjectColor.irregularColor;
    } else if (periodStatuses.contains(TimeTablePeriodStatus.regular)) {
      isRegularStatusColor = true;
      statusColor = ref.watch(customSubjectColorsProvider)[period.subject?.id] ?? CustomSubjectColor.regularColor;
    } else {
      statusColor = CustomSubjectColor.emptyColor;
    }

    Subject? subject = userData.subjects[period.subject?.id];
    Room? room = userData.rooms[period.room?.id];
    Teacher? teacher = userData.teachers[period.teacher?.id];
    Subject? orgSubject = userData.subjects[period.subject?.orgId];
    Room? orgRoom = userData.rooms[period.room?.orgId];
    Teacher? orgTeacher = userData.teachers[period.teacher?.orgId];

    Color textColor = periodStatuses.contains(TimeTablePeriodStatus.cancelled) ? Theme.of(context).textTheme.bodyLarge!.color! : statusColor.textColor;

    return Card(
      margin: const EdgeInsets.all(2),
      color: periodStatuses.contains(TimeTablePeriodStatus.cancelled) ? Theme.of(context).cardColor : statusColor.color,
      shape: periodStatuses.contains(TimeTablePeriodStatus.cancelled)
          ? RoundedRectangleBorder(
              side: BorderSide(
                color: statusColor.color,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          onTap(
            context,
            ref,
            isRegularStatusColor ? null : statusColor,
            subject,
            teacher,
            room,
            orgSubject,
            orgTeacher,
            orgRoom,
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool useShortText = constraints.maxWidth < 100 || orgSubject != subject || orgTeacher != teacher || orgRoom != room;
            String subjectText = (useShortText ? subject?.name : subject?.longName) ?? period.lessonText;
            String teacherText = (useShortText ? teacher?.shortName : teacher?.longName) ?? '';
            String roomText = room?.name ?? '';

            String? orgSubjectText = orgSubject != subject ? orgSubject?.name : '';
            String? orgTeacherText = orgTeacher != teacher ? orgTeacher?.shortName : '';
            String? orgRoomText = orgRoom != room ? orgRoom?.name : '';

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (subjectText.isNotEmpty || orgSubjectText.isNotNullOrEmpty())
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$orgSubjectText',
                            style: const TextStyle(
                              color: Colors.white60,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (orgSubjectText.isNotNullOrEmpty() && subjectText.isNotNullOrEmpty()) const TextSpan(text: ' '),
                          TextSpan(
                            text: subjectText,
                          ),
                        ],
                        style: TextStyle(
                          fontSize: fontSize,
                          color: textColor,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                if (teacherText.isNotEmpty || orgTeacherText.isNotNullOrEmpty())
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$orgTeacherText',
                            style: const TextStyle(
                              color: Colors.white60,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (orgTeacherText.isNotNullOrEmpty() && teacherText.isNotNullOrEmpty()) const TextSpan(text: ' '),
                          TextSpan(
                            text: teacherText,
                          ),
                        ],
                        style: TextStyle(
                          fontSize: fontSize,
                          color: textColor,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                if (roomText.isNotEmpty || orgRoomText.isNotNullOrEmpty())
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$orgRoomText',
                            style: const TextStyle(
                              color: Colors.white60,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (orgRoomText.isNotNullOrEmpty() && roomText.isNotNullOrEmpty()) const TextSpan(text: ' '),
                          TextSpan(
                            text: roomText,
                          ),
                        ],
                        style: TextStyle(
                          fontSize: fontSize,
                          color: textColor,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void onTap(
    BuildContext context,
    WidgetRef ref,
    CustomSubjectColor? statusColor,
    Subject? subject,
    Teacher? teacher,
    Room? room,
    Subject? orgSubject,
    Teacher? orgTeacher,
    Room? orgRoom,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeriodDetailsView(
          period: period,
          statusColor: statusColor,
          subject: subject,
          teacher: teacher,
          room: room,
          orgSubject: orgSubject,
          orgTeacher: orgTeacher,
          orgRoom: orgRoom,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

class PeriodDetailsView extends ConsumerWidget {
  final TimeTablePeriod period;
  final Subject? subject;
  final Teacher? teacher;
  final Room? room;
  final Subject? orgSubject;
  final Teacher? orgTeacher;
  final Room? orgRoom;
  final CustomSubjectColor? statusColor;

  const PeriodDetailsView({
    required this.period,
    required this.statusColor,
    this.subject,
    this.teacher,
    this.room,
    this.orgSubject,
    this.orgTeacher,
    this.orgRoom,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var customSubjectColor =
        ref.watch(customSubjectColorsProvider)[period.subject?.id] ?? CustomSubjectColor.regularColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: statusColor?.color ?? customSubjectColor.color,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
          const SizedBox(
            height: 8,
          ),
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
                        if (orgSubject != subject)
                          TextSpan(
                            text: orgSubject?.longName ?? period.subject?.id.toString() ?? period.lessonText,
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (orgSubject != subject) const TextSpan(text: ' '),
                        TextSpan(
                          text: subject?.longName ?? period.subject?.id.toString() ?? period.lessonText,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    "${intl.DateFormat("dd. MMM HH:mm").format(period.startTime)}-${intl.DateFormat("HH:mm").format(period.endTime)}",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 1,
          ),
          if (subject?.name != null && subject!.name.isNotEmpty && subject!.name != subject!.longName)
            ListTile(
              leading: const Icon(Icons.subject),
              title: const Text('Kurs'),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    if (orgSubject != subject)
                      TextSpan(
                        text: orgSubject?.name ?? period.subject?.id.toString() ?? period.lessonText,
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (orgSubject != subject) const TextSpan(text: ' '),
                    TextSpan(
                      text: subject!.name,
                    ),
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
                  if (orgTeacher != teacher)
                    TextSpan(
                      text: orgTeacher?.longName ?? 'Kein Lehrer',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (orgTeacher != teacher) const TextSpan(text: ' '),
                  TextSpan(
                    text: teacher?.longName ?? 'Kein Lehrer',
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
                  if (orgRoom != room)
                    TextSpan(
                      text: orgRoom?.name ?? 'Kein Raum',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (orgRoom != room) const TextSpan(text: ' '),
                  TextSpan(
                    text: room?.name ?? 'Kein Raum',
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Status'),
            subtitle: Text(
              period.periodStatus.map((e) => e.displayName).join(', '),
            ),
          ),
          if (period.infoText.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(period.infoText),
            ),
          if (period.lessonText.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: Text(period.lessonText),
            ),
          if (period.substitutionText.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: Text(period.substitutionText),
            ),
          const Divider(
            thickness: 1,
          ),
          if (period.subject != null)
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
                //einen color picker anzeigen
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Farbe ändern'),
                    content: MaterialColorPicker(
                      onColorChange: (color) {
                        Color textColor = color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white;
                        ref.read(customSubjectColorsProvider.notifier).add(
                              CustomSubjectColor(
                                period.subject!.id,
                                color,
                                textColor,
                              ),
                            );
                      },
                      selectedColor: customSubjectColor.color,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(customSubjectColorsProvider.notifier)
                              .remove(period.subject!.id);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Zurücksetzen'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Ok'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (period.subject != null)
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.red),
              title: const Text(
                'Kurs ausblenden',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                ref.read(filtersProvider.notifier).remove(period.subject!.id);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
