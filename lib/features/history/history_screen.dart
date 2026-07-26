import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/responsive_content.dart';
import 'history_controller.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    final filtered = history
        .where(
          (item) =>
              item.productName.toLowerCase().contains(_query.toLowerCase()) ||
              (item.brand ?? '').toLowerCase().contains(_query.toLowerCase()) ||
              item.barcode.contains(_query),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: history.isEmpty ? null : () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 700,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(
                ResponsiveInsets.compactHorizontal(context),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search history',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'No history',
                      message: 'Scanned products will appear here.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveInsets.compactHorizontal(context),
                        0,
                        ResponsiveInsets.compactHorizontal(context),
                        MediaQuery.paddingOf(context).bottom + 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Card(
                          child: ListTile(
                            leading: ProductImage(
                              imageUrl: item.imageUrl,
                              size: 52,
                            ),
                            title: Text(item.productName),
                            subtitle: Text(
                              [
                                item.brand,
                                item.rating,
                                item.scannedAt
                                    .toLocal()
                                    .toString()
                                    .split('.')
                                    .first,
                              ].whereType<String>().join(' • '),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              onPressed: () => ref
                                  .read(historyControllerProvider.notifier)
                                  .remove(item.barcode),
                              icon: const Icon(Icons.delete_outline),
                            ),
                            onTap: () =>
                                context.push('/product/${item.barcode}'),
                          ),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemCount: filtered.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear scan history?'),
        content: const Text(
          'This removes saved scan history from this device.',
        ),
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
      await ref.read(historyControllerProvider.notifier).clear();
    }
  }
}
