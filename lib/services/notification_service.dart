import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/expense_model.dart';

/// Manages local scheduled reminders and instant action notifications for SpendMate.
class NotificationService {
  static NotificationService? _instance;
  factory NotificationService() => _instance ??= NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification Channel IDs
  static const String _dailyReminderChannelId = 'spendmate_daily_reminders';
  static const String _alertsChannelId = 'spendmate_action_alerts';

  // Fixed Notification IDs
  static const int dailyReminderNotificationId = 1001;
  static const int actionAlertNotificationId = 2001;
  static const int budgetWarningNotificationId = 3001;

  /// Initialize notification plugin, timezone data, and channels.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully.');

      // Request permissions for Android 13+
      await requestPermissions();
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request runtime permissions (especially Android 13+ POST_NOTIFICATIONS).
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted =
            await androidImplementation?.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return false;
  }

  /// Schedule Daily Reminder (e.g. 8:30 PM every day)
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 30}) async {
    if (!_isInitialized) await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _dailyReminderChannelId,
        'Daily Reminders (दैनिक स्मरणपत्र)',
        channelDescription:
            'Reminds you every evening to record your daily hostel expenses.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        id: dailyReminderNotificationId,
        title: 'SpendMate 🔔 दैनिक स्मरणपत्र',
        body: 'आजचे खर्च नोंदवले का? बजेट नियंत्रणात ठेवण्यासाठी SpendMate अपडेट करा!',
        scheduledDate: scheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Daily reminder scheduled for $hour:$minute');
    } catch (e) {
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  /// Cancel Daily Reminder.
  Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
    } catch (e) {
      debugPrint('Error canceling daily reminder: $e');
    }
  }

  /// Trigger instant notification when an expense is recorded or added.
  Future<void> notifyExpenseAdded(
    Expense expense, {
    bool isOverBudget = false,
    double budgetUsagePercent = 0.0,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final String formattedAmount = '₹${expense.amount.toStringAsFixed(0)}';
      final String categoryName = expense.category.label;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _alertsChannelId,
        'SpendMate Alerts (खर्च व व्यवहार सूचना)',
        channelDescription:
            'Instant notifications for recorded expenses and budget warnings.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // 1. Transaction Alert
      await _notificationsPlugin.show(
        id: actionAlertNotificationId,
        title: 'खर्च नोंदवला गेला 💰 $formattedAmount',
        body: '${expense.title} ($categoryName) यशस्वीरित्या SpendMate मध्ये जोडला गेला.',
        notificationDetails: platformDetails,
      );

      // 2. Budget Alert if >= 80% or 100%
      if (budgetUsagePercent >= 0.8) {
        final percentText = (budgetUsagePercent * 100).toInt();
        final alertTitle = isOverBudget
            ? '⚠️ बजेट मर्यादा ओलांडली!'
            : '⚠️ बजेट इशारा ($percentText%)';
        final alertBody = isOverBudget
            ? 'आपण या महिन्याचे निश्चित बजेट ओलांडले आहे! खर्चावर नियंत्रण ठेवा.'
            : 'आपण मासिक बजेटच्या $percentText% रक्कम खर्च केली आहे.';

        await _notificationsPlugin.show(
          id: budgetWarningNotificationId,
          title: alertTitle,
          body: alertBody,
          notificationDetails: platformDetails,
        );
      }
    } catch (e) {
      debugPrint('Error showing expense notification: $e');
    }
  }

  /// Trigger instant notification when a roommate settlement or debt occurs.
  Future<void> notifySettlement(String roommateName, double amount) async {
    if (!_isInitialized) await initialize();

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _alertsChannelId,
        'SpendMate Alerts (खर्च व व्यवहार सूचना)',
        channelDescription: 'Settlement alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
      );

      await _notificationsPlugin.show(
        id: actionAlertNotificationId + 1,
        title: 'हिशोब पूर्ण झाला! ✅ ₹${amount.toStringAsFixed(0)}',
        body: '$roommateName सोबतचा हिशोब यशस्वीरित्या सेटल करण्यात आला आहे.',
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Error showing settlement notification: $e');
    }
  }
}
