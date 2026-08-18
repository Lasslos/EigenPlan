import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:your_schedule/core/provider/untis_session_provider.dart';
import 'package:your_schedule/core/untis.dart';
import 'package:your_schedule/settings/dashboard_cards_provider.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/announcements_card.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/exams_summary_card.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/homework_summary_card.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/messages_summary_card.dart';
import 'package:your_schedule/ui/screens/dashboard_screen/widgets/schedule_status_card.dart';
import 'package:your_schedule/util/week.dart';

const _examWeeksWatched = 3;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(selectedUntisSessionProvider) as ActiveUntisSession;
    final visibility = ref.watch(dashboardCardVisibilityProvider);
    bool isEnabled(DashboardCardType type) => !visibility.contains(type);
    final showMessages = session.loginMode != LoginMode.anonymous && isEnabled(DashboardCardType.messages);

    return Scaffold(
      appBar: AppBar(title: const Text('Start')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(requestHomeworkProvider(session));
          for (var i = 0; i < _examWeeksWatched; i++) {
            ref.invalidate(requestExamsProvider(session, Week.relative(i)));
          }
          if (showMessages) {
            ref.invalidate(requestMessagesProvider(session));
          }
          ref.invalidate(requestDashboardCardsProvider(session));
          await Future.wait([
            ref.read(requestHomeworkProvider(session).future),
            for (var i = 0; i < _examWeeksWatched; i++) ref.read(requestExamsProvider(session, Week.relative(i)).future),
            if (showMessages) ref.read(requestMessagesProvider(session).future),
            ref.read(requestDashboardCardsProvider(session).future),
          ]);
        },
        child: ListView(
          children: [
            if (isEnabled(DashboardCardType.schedule)) const ScheduleStatusCard(),
            if (isEnabled(DashboardCardType.homework)) const HomeworkSummaryCard(),
            if (isEnabled(DashboardCardType.exams)) const ExamsSummaryCard(),
            if (showMessages) const MessagesSummaryCard(),
            if (isEnabled(DashboardCardType.announcements)) const AnnouncementsCard(),
          ],
        ),
      ),
    );
  }
}
