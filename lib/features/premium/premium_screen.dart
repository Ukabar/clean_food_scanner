import 'package:flutter/material.dart';

import '../../core/widgets/responsive_content.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const _features = [
    'Unlimited scans',
    'Detailed additive analysis',
    'Personalized food preferences',
    'Product comparisons',
    'Better alternatives',
    'Full scan history',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ResponsiveContent(
        maxWidth: 650,
        child: ListView(
          padding: EdgeInsets.all(ResponsiveInsets.compactHorizontal(context)),
          children: [
            Text(
              'Premium features are coming soon.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ..._features.map(
              (feature) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(feature),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No subscription, pricing, Stripe, or in-app purchase flow is active in this version.',
            ),
          ],
        ),
      ),
    );
  }
}
