import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      // Add a subtle background gradient for depth
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [theme.colorScheme.background, theme.colorScheme.surface]
                : [theme.colorScheme.primary.withOpacity(0.05), theme.colorScheme.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Animated avatar for modern feel
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: AssetImage('assets/app_logo.png'), // Replace with user's avatar
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'John Doe', // Replace with user's name
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'john.doe@email.com', // Replace with user's email
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.7)),
                ),
                const SizedBox(height: 28),
                // Card with shadow and separated actions
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: theme.colorScheme.surface,
                  elevation: isDark ? 0 : 6,
                  shadowColor: theme.colorScheme.primary.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        _ProfileAction(
                          icon: Icons.edit,
                          label: 'Edit Profile',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileAction(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _ProfileAction(
                          icon: Icons.logout,
                          label: 'Logout',
                          onTap: () {},
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
