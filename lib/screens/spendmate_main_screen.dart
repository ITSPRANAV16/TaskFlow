import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import 'expense_dashboard_screen.dart';
import 'analytics_screen.dart';
import 'roommates_screen.dart';
import 'account_security_screen.dart';

class SpendMateMainScreen extends StatefulWidget {
  const SpendMateMainScreen({super.key});

  @override
  State<SpendMateMainScreen> createState() => _SpendMateMainScreenState();
}

class _SpendMateMainScreenState extends State<SpendMateMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ExpenseDashboardScreen(),
    AnalyticsScreen(),
    RoommatesScreen(),
    AccountSecurityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = context.watch<LocaleProvider>();
    final auth = context.watch<AuthService>();
    final showGuestBanner = loc.isGuestMode && !auth.isLoggedIn;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (showGuestBanner)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF451A03)
                      : const Color(0xFFFEF3C7),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.amber.shade900 : Colors.amber.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.tr('guest_warning'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            isDark ? Colors.white : Colors.amber.shade900,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentIndex = 3; // Go to Security/Account
                        });
                      },
                      child: Text(
                        loc.tr('connect_google'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: loc.tr('nav_expenses'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: const Icon(Icons.pie_chart_rounded),
              label: loc.tr('nav_analytics'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups_rounded),
              label: loc.tr('nav_roommates'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.security_outlined),
              selectedIcon: const Icon(Icons.security_rounded),
              label: loc.tr('nav_security'),
            ),
          ],
        ),
      ),
    );
  }
}
