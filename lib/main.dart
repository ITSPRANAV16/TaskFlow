import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/task_provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/crash_report_service.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'theme/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter Framework UI / Widget errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      CrashReportService.reportCrash(
        details.exception,
        details.stack,
      );
    };

    // Catch Platform / Async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      CrashReportService.reportCrash(error, stackTrace);
      return true;
    };

    // Initialize Smart Notification Service
    try {
      final notif = NotificationService();
      await notif.initialize();
      await notif.scheduleDailyReminder();
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }

    runApp(const SpendMateApp());
  }, (Object error, StackTrace stackTrace) {
    CrashReportService.reportCrash(error, stackTrace);
  });
}

class SpendMateApp extends StatelessWidget {
  const SpendMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CloudSyncService()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'SpendMate - Hostel Expense & Savings Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
