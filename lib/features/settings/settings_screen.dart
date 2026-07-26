import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/design_system.dart';
import '../../core/widgets/responsive_content.dart';
import '../../data/local/local_storage.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;
    final horizontalPadding = ResponsiveInsets.compactHorizontal(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ResponsiveContent(
        maxWidth: 650,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            bottom,
          ),
          children: [
            _SettingsSection(
              title: 'Appearance',
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) => ref
                        .read(settingsControllerProvider.notifier)
                        .setThemeMode(value.first),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Language',
              children: const [
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('English'),
                  subtitle: Text('More languages coming later.'),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Data',
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Clear scan history'),
                  onTap: () => _confirm(
                    context,
                    'Clear scan history?',
                    () => LocalStorage.instance.clearHistory(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cached_outlined),
                  title: const Text('Clear cached products'),
                  onTap: () => _confirm(
                    context,
                    'Clear cached products?',
                    () => LocalStorage.instance.clearCache(),
                  ),
                ),
              ],
            ),
            _SettingsSection(
              title: 'Legal',
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Needs production URL before release.'),
                  onTap: () => _open(AppConstants.privacyPolicyUrl),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Use'),
                  subtitle: const Text('Needs production URL before release.'),
                  onTap: () => _open(AppConstants.termsUrl),
                ),
              ],
            ),
            _SettingsSection(
              title: 'About',
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: Text(
                      'Version ${snapshot.data?.version ?? '1.0.0'}',
                    ),
                    onTap: () => _showAbout(context, snapshot.data),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    Future<void> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This only affects data stored on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Done.')));
      }
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showAbout(BuildContext context, PackageInfo? info) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ResponsiveContent(
          maxWidth: 650,
          expandHeight: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text('Version ${info?.version ?? '1.0.0'}'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Uses Open Food Facts data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(AppLocalizations.of(context).disclaimer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Card(child: Column(children: children)),
        ],
      ),
    );
  }
}
