import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'services/crash_report_service.dart';

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

    runApp(const TaskFlowApp());
  }, (Object error, StackTrace stackTrace) {
    CrashReportService.reportCrash(error, stackTrace);
  });
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'TaskFlow - Modern Task Manager',
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
