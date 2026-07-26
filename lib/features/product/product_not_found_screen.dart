import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_system.dart';
import '../../core/widgets/responsive_content.dart';

class ProductNotFoundScreen extends StatelessWidget {
  const ProductNotFoundScreen({required this.barcode, super.key});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;
    return Scaffold(
      appBar: AppBar(title: const Text('Product lookup')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ResponsiveContent(
            maxWidth: 650,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveInsets.horizontal(context),
                16,
                ResponsiveInsets.horizontal(context),
                bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 42,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Product not found',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'This barcode is not currently available in the Open Food Facts food database. Make sure you scanned a food or beverage product.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              'Scanned barcode',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            SelectableText(
                              barcode,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => context.go('/scanner'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan another product'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/manual-barcode'),
                      icon: const Icon(Icons.keyboard_outlined),
                      label: const Text('Enter barcode manually'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
