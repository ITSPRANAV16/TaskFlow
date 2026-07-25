import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AboutSheet(),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Logo & Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryViolet.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TaskFlow',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryViolet,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A Modern Task Manager App\nBuilt with Flutter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Divider
            Divider(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 20),

            // Developer Section Header
            Row(
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 18,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  'Developer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Developer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBg : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'PP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pranav Patil',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 14,
                              color: AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Android Developer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Social Links
            Row(
              children: [
                // GitHub Button
                Expanded(
                  child: _buildSocialButton(
                    context,
                    icon: Icons.code_rounded,
                    label: 'GitHub',
                    color: isDark ? Colors.white : const Color(0xFF171515),
                    bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onTap: () => _launchUrl('https://github.com/ITSPRANAV16'),
                  ),
                ),
                const SizedBox(width: 12),
                // Instagram Button
                Expanded(
                  child: _buildSocialButton(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    onTap: () => _launchUrl('https://www.instagram.com/pranav_patil__16?igsh=Ym0wY2s3ZGx1M244'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Check for Updates Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                onPressed: () => UpdateService.checkForUpdates(context, showNoUpdateToast: true),
                icon: const Icon(Icons.system_update_rounded, size: 18, color: AppTheme.primaryViolet),
                label: Text(
                  'Check for Updates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Text(
              '© 2026 Pranav Patil. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
