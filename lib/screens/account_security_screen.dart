import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
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
    final syncService = context.watch<CloudSyncService>();
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
            // ── 1. Google Account Profile Card ──
            _buildGoogleAccountCard(
                auth, syncService, expenseProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 2. Cloud Sync & Zero Data Loss Vault ──
            _buildCloudSyncCard(
                auth, syncService, expenseProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 3. App Lock & Biometrics (USE WITH SECURITY) ──
            _buildSecurityCard(security, loc, isDark),
            const SizedBox(height: 16),

            // ── 4. Notifications Preference Card ──
            _buildNotificationCard(loc, isDark),
            const SizedBox(height: 16),

            // ── 5. Language Selection Card ──
            _buildLanguageCard(loc, isDark),
            const SizedBox(height: 16),

            // ── 6. App Theme & Info ──
            _buildThemeAndInfoCard(taskProvider, loc, isDark),
            const SizedBox(height: 16),

            // ── 7. Data Safety & Cloud Guard Modal ──
            _buildDataSafetyCard(
                expenseProvider, syncService, auth, loc, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleAccountCard(
    AuthService auth,
    CloudSyncService syncService,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
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
                      user != null ? user.name : 'अतिथी वापरकर्ता (Guest)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? user.email
                          : 'गुगल लॉगिन करून डेटा क्लाऊडवर सुरक्षित करा',
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
                    label: const Text('साइन आउट'),
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
                              // Perform Zero-Data-Loss Two-Way Sync immediately
                              final merged = await syncService.syncWithCloud(
                                accountEmail: loggedInUser.email,
                                currentLocalExpenses:
                                    expenseProvider.allExpenses,
                              );
                              if (merged != null) {
                                expenseProvider.setMergedExpenses(merged);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              _showCustomAccountDialog(
                                  context, auth, syncService, expenseProvider);
                            }
                          }
                        },
                  icon: const Icon(Icons.account_circle_rounded),
                  label: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

  void _showCustomAccountDialog(
    BuildContext context,
    AuthService auth,
    CloudSyncService syncService,
    ExpenseProvider expenseProvider,
  ) {
    final nameCtrl = TextEditingController(text: 'SpendMate User');
    final emailCtrl = TextEditingController(text: 'user@gmail.com');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Google खाते कनेक्ट करा'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'आपला ईमेल जोडून क्लाऊड बॅकअप सुरक्षित करा. कोणताही डेटा डिलीट होणार नाही.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'नाव (Name)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Gmail पत्ता'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करा'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isNotEmpty) {
                final user = await auth.signInWithCustomAccount(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                );
                final merged = await syncService.syncWithCloud(
                  accountEmail: user.email,
                  currentLocalExpenses: expenseProvider.allExpenses,
                );
                if (merged != null) {
                  expenseProvider.setMergedExpenses(merged);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('कनेक्ट करा'),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard(
    AuthService auth,
    CloudSyncService syncService,
    ExpenseProvider expenseProvider,
    LocaleProvider loc,
    bool isDark,
  ) {
    final isSynced = syncService.syncStatus == SyncStatus.synced;
    final lastTimeStr = syncService.lastSyncTime != null
        ? DateFormat('dd MMM, hh:mm a').format(syncService.lastSyncTime!)
        : 'कधीही नाही';

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
                    Icons.cloud_done_rounded,
                    color: isSynced
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'क्लाऊड व्हॉल्ट (Zero Data Loss)',
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
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSynced ? 'सुरक्षित सिंक' : 'स्थानिक सुरक्षित',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSynced
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'शेवटचे सिंक: $lastTimeStr',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final email = auth.currentUser?.email ?? 'local_user@spendmate.app';
              final merged = await syncService.syncWithCloud(
                accountEmail: email,
                currentLocalExpenses: expenseProvider.allExpenses,
              );
              if (merged != null) {
                expenseProvider.setMergedExpenses(merged);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✅ सर्व डेटा सुरक्षितपणे सिंक झाला (Zero Data Loss)',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text('आता सिंक करा (Sync Now)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
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
              '8:30 PM reminder to log daily expenses',
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
              NotificationService().notifySettlement('Friend', 250);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Test notification sent!'),
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
                'SpendMate Version',
                style: TextStyle(fontSize: 13),
              ),
              const Text(
                'v1.1.0 (Ultra)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
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
    CloudSyncService syncService,
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
              syncService,
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
    CloudSyncService syncService,
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
              final email =
                  auth.currentUser?.email ?? 'backup_user@gmail.com';
              await syncService.syncWithCloud(
                accountEmail: email,
                currentLocalExpenses: expenseProvider.allExpenses,
              );
              expenseProvider.clearAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('✅ Data synced & backed up safely before clear!'),
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

