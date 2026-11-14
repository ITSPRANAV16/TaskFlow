import 'package:flutter/material.dart';
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'खर्च (Expenses)',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline_rounded),
              selectedIcon: Icon(Icons.pie_chart_rounded),
              label: 'विश्लेषण (Analytics)',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'रूममेट्स (Splits)',
            ),
            NavigationDestination(
              icon: Icon(Icons.security_outlined),
              selectedIcon: Icon(Icons.security_rounded),
              label: 'सुरक्षा (Security)',
            ),
          ],
        ),
      ),
    );
  }
}

