import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/design_system.dart';
import '../core/widgets/responsive_content.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _AppBottomNavigation(),
    );
  }
}

class _AppBottomNavigation extends StatelessWidget {
  const _AppBottomNavigation();

  static const _items = [
    _NavItem('Home', Icons.home_rounded, '/'),
    _NavItem('Scan', Icons.qr_code_scanner_rounded, '/scanner'),
    _NavItem('Favorites', Icons.favorite_border_rounded, '/favorites'),
    _NavItem('History', Icons.history_rounded, '/history'),
    _NavItem('Settings', Icons.tune_rounded, '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = GoRouterState.of(context).uri.path;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ResponsiveContent(
        maxWidth: 720,
        expandHeight: false,
        child: DecoratedBox(
          key: const ValueKey('home_bottom_nav'),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.24
                      : 0.10,
                ),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset > 0 ? 6 : 8),
            child: Row(
              children: [
                for (final item in _items)
                  Expanded(
                    child: _BottomNavItem(
                      item: item,
                      selected: _isSelected(path, item.path),
                      onTap: () => _openItem(context, path, item.path),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isSelected(String currentPath, String itemPath) {
    if (itemPath == '/scanner') {
      return false;
    }
    return currentPath == itemPath;
  }

  static void _openItem(BuildContext context, String currentPath, String path) {
    if (path == '/scanner') {
      context.push(path);
      return;
    }
    if (currentPath != path) {
      context.go(path);
    }
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final keyName = item.label.toLowerCase();
    final foreground = selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        key: ValueKey('bottom_nav_$keyName'),
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: foreground, size: selected ? 24 : 23),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}
