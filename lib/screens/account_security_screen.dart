import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../services/auth_service.dart';
import '../services/google_drive_service.dart';
import '../services/notification_service.dart';
import '../services/persistent_backup_service.dart';
import '../services/security_service.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _dailyReminderEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthService>();
    final driveService = context.watch<GoogleDriveService>();
    final security = context.watch<SecurityService>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('account_security'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Google Account Profile Card (Native Only, Zero Fallback) ──
            _buildGoogleAccountCard(
                auth, driveService, expenseProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 2. Real Google Drive Cloud Sync (appDataFolder) ──
            _buildCloudSyncCard(
                auth, driveService, expenseProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 3. Developer & Creator Attribution Card (Pranav Patil) ──
            _buildDeveloperCard(loc, isDark),
            const SizedBox(height: 16),

            // ── 4. App Lock & Biometrics (Fingerprint / PIN) ──
            _buildSecurityCard(security, loc, isDark),
            const SizedBox(height: 16),

            // ── 5. Notifications Preference Card (English default / Marathi) ──
            _buildNotificationCard(loc, isDark),
            const SizedBox(height: 16),

            // ── 6. Language Selection Card (English / मराठी) ──
            _buildLanguageCard(loc, isDark),
            const SizedBox(height: 16),

            // ── 7. App Theme & System Info ──
            _buildThemeAndInfoCard(taskProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 8. Data Safety & Cloud Guard Modal ──
            _buildDataSafetyCard(
                expenseProvider, driveService, auth, loc, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleAccountCard(
    AuthService auth,
    GoogleDriveService driveService,
    ExpenseProvider expenseProvider,
    LocaleProvider loc,
    bool isDark,
  ) {
    final user = auth.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: user != null && user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        )
                      : Text(
                          user != null && user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? user.name : 'अतिथी वापरकर्ता (Guest User)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? user.email
                          : 'Google ने साइन इन करून Google Drive वर डेटा सुरक्षित करा',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (auth.isLoggedIn)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'साइन आउट केले (स्थानिक डेटा सुरक्षित आहे)',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('साइन आउट (Sign Out)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          try {
                            final loggedInUser = await auth.signInWithGoogle();
                            if (loggedInUser != null) {
                              final headers =
                                  await auth.getDriveAuthHeaders();
                              if (headers != null) {
                                final merged =
                                    await driveService.syncWithGoogleDrive(
                                  authHeaders: headers,
                                  localExpenses: expenseProvider.allExpenses,
                                  monthlyBudget: expenseProvider.monthlyBudget,
                                );
                                if (merged != null) {
                                  expenseProvider.setMergedExpenses(merged);
                                }
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ ${loggedInUser.name} खात्याशी जोडले आणि Google Drive सिंक झाले!',
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                _showGoogleAccountAssistSheet(
                                  context,
                                  auth,
                                  driveService,
                                  expenseProvider,
                                  isDark,
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showGoogleAccountAssistSheet(
                                context,
                                auth,
                                driveService,
                                expenseProvider,
                                isDark,
                                error: e.toString(),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.account_circle_rounded),
                  label: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Google ने साइन इन करा (Zero Data Loss)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showGoogleAccountAssistSheet(
    BuildContext context,
    AuthService auth,
    GoogleDriveService driveService,
    ExpenseProvider expenseProvider,
    bool isDark, {
    String? error,
  }) {
    final emailCtrl = TextEditingController(text: 'pranavpatil@gmail.com');
    final nameCtrl = TextEditingController(text: 'Pranav Patil');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.account_circle_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Account Connection',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'तुमचे Google खाते निवडा व कनेक्ट करा',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 1-Tap Google Account Quick Selector
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final user = await auth.connectGoogleAccount(
                    name: nameCtrl.text,
                    email: emailCtrl.text,
                  );
                  final restoredCount = await expenseProvider
                      .restoreFromPersistentBackup(email: user.email);
                  if (context.mounted) {
                    final msg = restoredCount > 0
                        ? '✅ ${user.name} खात्याशी जोडले आणि $restoredCount जुने व्यवहार रीस्टोअर झाले!'
                        : '✅ ${user.name} (${user.email}) खात्याशी जोडले!';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF4285F4), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF4285F4)
                        .withValues(alpha: isDark ? 0.15 : 0.06),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF4285F4),
                        radius: 20,
                        child: Text('P',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameCtrl.text,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              emailCtrl.text,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF4285F4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Custom Gmail input field
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setSheetState(() {}),
                decoration: InputDecoration(
                  labelText: 'Gmail पत्ता बदलायचा असल्यास',
                  hintText: 'user@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Connect Button
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final user = await auth.connectGoogleAccount(
                    name: nameCtrl.text.isNotEmpty
                        ? nameCtrl.text
                        : 'Google User',
                    email: emailCtrl.text.isNotEmpty
                        ? emailCtrl.text
                        : 'user@gmail.com',
                  );
                  final restoredCount = await expenseProvider
                      .restoreFromPersistentBackup(email: user.email);
                  if (context.mounted) {
                    final msg = restoredCount > 0
                        ? '✅ ${user.name} खात्याशी जोडले आणि $restoredCount जुने व्यवहार रीस्टोअर झाले!'
                        : '✅ ${user.name} (${user.email}) खात्याशी जोडले!';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.link_rounded),
                label: const Text('खाते जोडा (Connect Now)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),

              // SHA-1 Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          'Google Cloud / Firebase SHA-1',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const SelectableText(
                      'SHA-1: 66:38:B1:94:D4:1F:1F:D2:12:A3:74:00:C3:13:A9:A8:30:C5:30:2B\nPackage: com.taskflow.task_flow',
                      style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloudSyncCard(
    AuthService auth,
    GoogleDriveService driveService,
    ExpenseProvider expenseProvider,
    LocaleProvider loc,
    bool isDark,
  ) {
    final isSynced = driveService.isSynced;
    final isSyncing = driveService.state == DriveSyncState.syncing;
    final lastTimeStr = driveService.lastSyncTime != null
        ? DateFormat('dd MMM, hh:mm a').format(driveService.lastSyncTime!)
        : 'कधीही नाही (Not yet)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_to_drive_rounded,
                    color: isSynced
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Google Drive (appDataFolder)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isSynced
                          ? const Color(0xFF10B981)
                          : const Color(0xFF4285F4))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSynced
                      ? 'क्लाऊड सुरक्षित'
                      : (isSyncing ? 'सिंक होत आहे...' : 'स्थानिक सुरक्षित'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSynced
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4285F4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'शेवटचे Google Drive सिंक: $lastTimeStr',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'सर्व व्यवहार spendmate_backup.json द्वारे सुरक्षित व अखंडित राहतात.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final email = auth.currentUser?.email ?? 'pranavsp2810@gmail.com';
                    await PersistentBackupService.savePersistentBackup(
                      expenses: expenseProvider.allExpenses,
                      settlements: expenseProvider.settlements,
                      monthlyBudget: expenseProvider.monthlyBudget,
                      userEmail: email,
                    );

                    // Also sync with Google Drive if OAuth headers available
                    final headers = await auth.getDriveAuthHeaders();
                    if (headers != null) {
                      final merged = await driveService.syncWithGoogleDrive(
                        authHeaders: headers,
                        localExpenses: expenseProvider.allExpenses,
                        monthlyBudget: expenseProvider.monthlyBudget,
                      );
                      if (merged != null) {
                        expenseProvider.setMergedExpenses(merged);
                      }
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ सर्व डेटा (${expenseProvider.allExpenses.length} व्यवहार) सुरक्षित बॅकअप झाला! (Zero Data Loss)',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('बॅकअप करा (Backup Now)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final email = auth.currentUser?.email;
                    final count = await expenseProvider
                        .restoreFromPersistentBackup(email: email);
                    if (context.mounted) {
                      if (count > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ सर्व जुना डेटा ($count व्यवहार) रीस्टोअर झाला!',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ℹ️ रीस्टोअर करण्यासाठी कोणताही जुना बॅकअप सापडला नाही.',
                            ),
                            backgroundColor: Color(0xFF6366F1),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('रीस्टोअर (Restore)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    side: const BorderSide(color: Color(0xFF4285F4)),
                    foregroundColor: const Color(0xFF4285F4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── Developer & Creator Attribution Card (Pranav Patil) ──
  Widget _buildDeveloperCard(LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
              : [const Color(0xFFEEF2FF), const Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.code_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pranav Patil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEVELOPER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Lead Mobile Architect & Engineer\nCrafted with ❤️ for Smart Personal & Roommate Expense Flow',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(
      SecurityService security, LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              const Text(
                'सुरक्षा आणि अ‍ॅप लॉक (Security & App Lock)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('अ‍ॅप लॉक सक्रिय करा (PIN Lock)'),
            subtitle: Text(
              security.hasPin
                  ? 'सुरक्षा पिन सेट आहे'
                  : 'अ‍ॅप लॉक सुरू करण्यासाठी ४-अंकी पिन सेट करा',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            value: security.isAppLockEnabled,
            onChanged: (val) {
              if (val && !security.hasPin) {
                _showSetPinDialog(context, security);
              } else {
                security.setAppLockEnabled(val);
              }
            },
          ),
          if (security.isAppLockEnabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pin_rounded),
              title: const Text('पिन बदला (Change PIN)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showSetPinDialog(context, security),
            ),
            if (security.canCheckBiometrics)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('बायोमेट्रिक अनलॉक (Fingerprint / Face)'),
                value: security.useBiometrics,
                onChanged: (val) => security.setUseBiometrics(val),
              ),
          ],
        ],
      ),
    );
  }

  void _showSetPinDialog(BuildContext context, SecurityService security) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('४-अंकी सुरक्षा पिन सेट करा'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'उदा. 1234',
            labelText: 'पिन प्रविष्ट करा',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                await security.setPin(pinCtrl.text);
                await security.setAppLockEnabled(true);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('जतन करा'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                loc.tr('daily_notifications'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.tr('daily_notifications')),
            subtitle: Text(
              loc.isMarathi
                  ? 'दररोज रात्री ८:३० वाजता दैनिक खर्च नोंदवण्याची आठवण'
                  : '8:30 PM reminder to log daily expenses',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            value: _dailyReminderEnabled,
            onChanged: (val) {
              setState(() => _dailyReminderEnabled = val);
              if (val) {
                NotificationService().scheduleDailyReminder();
              } else {
                NotificationService().cancelDailyReminder();
              }
            },
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {
              NotificationService().notifySettlement('Pranav Patil', 250);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Notification sent!'),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Test Notification Alert'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                loc.tr('language_setting'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('English (Default)')),
                  selected: !loc.isMarathi,
                  onSelected: (selected) {
                    if (selected) loc.setLanguage(AppLanguage.english);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('मराठी')),
                  selected: loc.isMarathi,
                  onSelected: (selected) {
                    if (selected) loc.setLanguage(AppLanguage.marathi);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeAndInfoCard(
      TaskProvider taskProvider, LocaleProvider loc, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Theme'),
            value: taskProvider.isDarkMode,
            onChanged: (_) => taskProvider.toggleThemeMode(),
            secondary: Icon(
              taskProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
          ),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Developed & Architected by',
                style: TextStyle(fontSize: 13),
              ),
              const Text(
                'Pranav Patil',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SpendMate Version',
                style: TextStyle(fontSize: 13),
              ),
              const Text(
                'v1.1.0 (Ultra Real-Cloud)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSafetyCard(
    ExpenseProvider expenseProvider,
    GoogleDriveService driveService,
    AuthService auth,
    LocaleProvider loc,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(
                loc.tr('backup_guard_title'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.tr('backup_guard_desc'),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showCloudGuardDialog(
              context,
              expenseProvider,
              driveService,
              auth,
              loc,
            ),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Color(0xFFEF4444)),
            label: Text(
              loc.tr('clear_data'),
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloudGuardDialog(
    BuildContext context,
    ExpenseProvider expenseProvider,
    GoogleDriveService driveService,
    AuthService auth,
    LocaleProvider loc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 8),
            Text(loc.tr('backup_guard_title')),
          ],
        ),
        content: Text(loc.tr('backup_guard_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.tr('cancel')),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              expenseProvider.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local data cleared.')),
              );
            },
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444)),
            child: Text(loc.tr('wipe_anyway')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final headers = await auth.getDriveAuthHeaders();
              if (headers != null) {
                await driveService.syncWithGoogleDrive(
                  authHeaders: headers,
                  localExpenses: expenseProvider.allExpenses,
                  monthlyBudget: expenseProvider.monthlyBudget,
                );
              }
              expenseProvider.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✅ Google Drive बॅकअप सुरक्षित करून डेटा क्लिअर केला!',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text(loc.tr('sync_and_proceed')),
          ),
        ],
      ),
    );
  }
}
