import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class CrashReportService {
  static const String _githubRepo = 'ITSPRANAV16/TaskFlow';
  static const String _tokenFromEnv = String.fromEnvironment('GITHUB_TOKEN');
  static final Set<String> _reportedErrorHashes = {};

  static Future<void> reportCrash(Object error, StackTrace? stackTrace) async {
    try {
      final String errorMsg = error.toString();
      final String errorHash = errorMsg.hashCode.toString();

      // Deduplicate recent identical crashes
      if (_reportedErrorHashes.contains(errorHash)) {
        debugPrint('[CrashReportService] Duplicate crash ignored: $errorMsg');
        return;
      }
      _reportedErrorHashes.add(errorHash);

      final String deviceInfo = await _getDeviceInfo();
      final String appVersion = await _getAppVersion();
      final String stackStr = (stackTrace != null) ? stackTrace.toString() : 'No StackTrace available';

      final String title = '🐛 [Crash Report] ${errorMsg.length > 80 ? errorMsg.substring(0, 80) : errorMsg}';
      
      final String body = '''
## 🐛 TaskFlow Crash Report

**App Version**: `$appVersion`
**Device Info**: `$deviceInfo`
**Timestamp**: `${DateTime.now().toUtc().toIso8601String()} UTC`

### ❌ Error Exception:
```text
$errorMsg
```

### 📑 Stack Trace:
```text
${stackStr.length > 1500 ? stackStr.substring(0, 1500) + '\n... (truncated)' : stackStr}
```

---
*This crash report was automatically caught and submitted by TaskFlow App.*
''';

      // Send to GitHub Issues API if token is configured
      if (_tokenFromEnv.isNotEmpty) {
        await _postToGitHubIssues(title, body);
      } else {
        debugPrint('[CrashReportService] GITHUB_TOKEN not provided via --dart-define. Logged crash locally: $title');
      }
    } catch (e) {
      debugPrint('[CrashReportService] Failed to submit crash report: $e');
    }
  }

  static Future<void> _postToGitHubIssues(String title, String body) async {
    final uri = Uri.parse('https://api.github.com/repos/$_githubRepo/issues');
    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': 'Bearer $_tokenFromEnv',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'labels': ['bug', 'crash-report'],
      }),
    );

    if (response.statusCode == 201) {
      debugPrint('[CrashReportService] ✅ Successfully posted GitHub Issue crash report!');
    } else {
      debugPrint('[CrashReportService] Failed to post GitHub Issue: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webkitInfo;
        return 'Web (${webInfo.userAgent})';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} (${androidInfo.manufacturer} ${androidInfo.model}, API ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion} (${iosInfo.name} ${iosInfo.model})';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        return 'Windows ${winInfo.majorVersion}.${winInfo.minorVersion} (${winInfo.computerName})';
      }
    } catch (e) {
      debugPrint('[CrashReportService] Failed to get device info: $e');
    }
    return 'Unknown Device Platform';
  }

  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return 'v${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      return 'v1.0.1+2';
    }
  }
}
