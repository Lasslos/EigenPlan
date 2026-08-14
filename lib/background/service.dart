import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:your_schedule/util/logger.dart';

// ToDo: Background fetch and notifications
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    getLogger().i('Background fetch triggered');

    try {
      await performBackgroundFetch();
    } catch (e, s) {
      getLogger().e('Background fetch failed', error: e, stackTrace: s);
      await Sentry.captureException(e, stackTrace: s);
    }
    return true;
  });
}

Future<void> performBackgroundFetch() async {
  // 1. Fetch data
  // 2. Read data from local storage
  // 3. compare => If different, send notification
  // 4. Write data to local storage
}

Future<void> sendMessage(String title, String message, {int id = 0}) async {
  var androidDetails = AndroidNotificationDetails(
      '', '',
      channelDescription: 'Benachrichtigungen über den Vertretungsplan',

      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(message),
      ongoing: false,
      icon: '@drawable/ic_launcher',
  );
  var platformDetails = NotificationDetails(android: androidDetails);
  await FlutterLocalNotificationsPlugin()
      .show(id: id, title: title, body: message, notificationDetails: platformDetails);
}
