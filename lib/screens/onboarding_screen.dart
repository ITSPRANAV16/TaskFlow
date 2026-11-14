import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/task_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'security_lock_screen.dart';
import 'spendmate_main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _notificationGranted = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context, {required bool isGuest}) async {
    final loc = context.read<LocaleProvider>();
    await loc.setGuestMode(isGuest);
    await loc.completeOnboarding();

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SecurityLockScreen(
          child: SpendMateMainScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top indicator & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF6366F1)
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  if (_currentPage < 3)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(isDark, loc),
                  _buildLanguageThemePage(context, isDark, loc),
                  _buildPermissionsPage(context, isDark, loc),
                  _buildAccountChoicePage(context, isDark, loc),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.all(20),
              child: _currentPage < 3
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Welcome
  Widget _buildWelcomePage(bool isDark, LocaleProvider loc) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 54,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'SpendMate',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Smart Expense & Hostel Split Manager',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Effortlessly manage personal budgets, track daily spend limits, split hostel bills with roommates, and settle up with 1-tap UPI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Language & Theme
  Widget _buildLanguageThemePage(
      BuildContext context, bool isDark, LocaleProvider loc) {
    final taskProv = context.watch<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred language and display theme.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          // Language Selector
          const Text(
            'Language / भाषा',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectCard(
                  title: 'English',
                  subtitle: 'Default UI',
                  isSelected: !loc.isMarathi,
                  isDark: isDark,
                  onTap: () => loc.setLanguage(AppLanguage.english),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectCard(
                  title: 'मराठी',
                  subtitle: 'मराठी भाषा',
                  isSelected: loc.isMarathi,
                  isDark: isDark,
                  onTap: () => loc.setLanguage(AppLanguage.marathi),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Theme Selector
          const Text(
            'App Theme',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSelectCard(
                  title: 'Dark Theme',
                  subtitle: 'Fintech Neon',
                  icon: Icons.dark_mode_rounded,
                  isSelected: taskProv.isDarkMode,
                  isDark: isDark,
                  onTap: () {
                    if (!taskProv.isDarkMode) {
                      taskProv.toggleThemeMode();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectCard(
                  title: 'Light Theme',
                  subtitle: 'Clean & Bright',
                  icon: Icons.light_mode_rounded,
                  isSelected: !taskProv.isDarkMode,
                  isDark: isDark,
                  onTap: () {
                    if (taskProv.isDarkMode) {
                      taskProv.toggleThemeMode();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Permissions
  Widget _buildPermissionsPage(
      BuildContext context, bool isDark, LocaleProvider loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Permissions & Access',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'SpendMate requires a few permissions to provide automated reminders and security.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),

          // Notification Permission
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Notifications',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daily 8:30 PM reminder & instant spending threshold alerts.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _notificationGranted
                      ? null
                      : () async {
                          await NotificationService().requestPermissions();
                          setState(() => _notificationGranted = true);
                        },
                  child: Text(_notificationGranted ? 'Granted' : 'Allow'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Security & UPI info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Biometric & PIN Security',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep your finances private with device fingerprint or 4-digit PIN.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Account Choice
  Widget _buildAccountChoicePage(
      BuildContext context, bool isDark, LocaleProvider loc) {
    final auth = context.watch<AuthService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect Your Account',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you would like to use SpendMate.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Google Sign-In Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEEF2FF), Colors.white],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.g_mobiledata_rounded,
                          color: Color(0xFF4285F4), size: 30),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Account (Recommended)',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Zero Data Loss cloud backup & multi-device sync',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            try {
                              final user = await auth.signInWithGoogle();
                              if (user != null && context.mounted) {
                                _finishOnboarding(context, isGuest: false);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        'Google Sign-In canceled or unavailable.'),
                                    action: SnackBarAction(
                                      label: 'Guest Mode',
                                      onPressed: () => _finishOnboarding(
                                          context,
                                          isGuest: true),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    icon: auth.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login_rounded),
                    label: const Text('Sign In with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Guest Mode Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline_rounded,
                          color: Colors.amber, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue as Guest (Offline)',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Data is saved only locally on this phone',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _finishOnboarding(context, isGuest: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue as Guest'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Developed by Pranav Patil',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final activeColor = const Color(0xFF6366F1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (icon != null)
                  Icon(icon,
                      size: 20, color: isSelected ? activeColor : Colors.grey)
                else
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : null,
                    ),
                  ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: isSelected ? activeColor : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (icon != null)
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : null,
                ),
              ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

