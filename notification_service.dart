import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── Initialize ──────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    // Android permission request (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('[NotificationService] Initialized ✅');
  }

  // ─── Notification Details ─────────────────────────────────────────
  static NotificationDetails get _notifDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'money_target_channel',
      'Money Target Reminders',
      channelDescription: 'Reminds you to make your scheduled payment',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─── Cancel all existing notifications ───────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  // ─── Schedule based on plan type ─────────────────────────────────
  static Future<void> scheduleForPlan({
    required String planType,
    required double targetAmount,
    required DateTime savedAt, // target save ചെയ്ത time
  }) async {
    await init();
    await cancelAll(); // Old notifications clear ചെയ്യുക

    final amountStr = targetAmount.toStringAsFixed(0);

    switch (planType) {
      case 'Daily':
        await _scheduleDaily(
          title: '💰 Daily Payment Reminder',
          body: 'Time to add your daily payment towards ₹$amountStr target!',
          hour: savedAt.hour,
          minute: savedAt.minute,
        );
        break;

      case 'Weekly':
        await _scheduleWeekly(
          title: '📅 Weekly Payment Reminder',
          body:
              'Your weekly payment is due! Add it to your ₹$amountStr target.',
          weekday: savedAt.weekday, // 1=Monday ... 7=Sunday
          hour: savedAt.hour,
          minute: savedAt.minute,
        );
        break;

      case 'Monthly':
        await _scheduleMonthly(
          title: '🎯 Monthly Payment Reminder',
          body:
              'It\'s time for your monthly payment! Keep going towards ₹$amountStr.',
          dayOfMonth: savedAt.day,
          hour: savedAt.hour,
          minute: savedAt.minute,
        );
        break;
    }

    debugPrint(
      '[NotificationService] Scheduled $planType notification for ₹$amountStr',
    );
  }

  // ─── Daily: Every day at same time ───────────────────────────────
  static Future<void> _scheduleDaily({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Time കഴിഞ്ഞെങ്കിൽ നാളെ schedule ചെയ്യുക
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 1001,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NotificationService] Daily scheduled at $hour:$minute');
  }

  // ─── Weekly: Same weekday every week ─────────────────────────────
  static Future<void> _scheduleWeekly({
    required String title,
    required String body,
    required int weekday, // DateTime.weekday: 1=Mon, 7=Sun
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Next occurrence of this weekday കണ്ടുപിടിക്കൂ
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Correct weekday വരെ forward ചെയ്യൂ
    while (scheduledDate.weekday != weekday ||
        scheduledDate.isBefore(now.add(const Duration(minutes: 1)))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 1002,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint(
      '[NotificationService] Weekly scheduled on weekday=$weekday at $hour:$minute',
    );
  }

  // ─── Monthly: Same day every month ───────────────────────────────
  static Future<void> _scheduleMonthly({
    required String title,
    required String body,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // This month-ൽ ആ date വന്നോ? ഇല്ലെങ്കിൽ next month
    var year = now.year;
    var month = now.month;

    var scheduledDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      dayOfMonth,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now.add(const Duration(minutes: 1)))) {
      // Next month
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      scheduledDate = tz.TZDateTime(
        tz.local,
        year,
        month,
        dayOfMonth,
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      id: 1003,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    debugPrint(
      '[NotificationService] Monthly scheduled on day=$dayOfMonth at $hour:$minute',
    );
  }
}
