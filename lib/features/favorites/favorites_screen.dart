import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/responsive_content.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);
    final horizontalPadding = ResponsiveInsets.compactHorizontal(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ResponsiveContent(
        maxWidth: 700,
        child: favorites.isEmpty
            ? const EmptyState(
                icon: Icons.favorite_outline,
                title: 'No favorites',
                message:
                    'Add products to favorites from the product details screen.',
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return Card(
                    child: ListTile(
                      leading: ProductImage(imageUrl: item.imageUrl, size: 52),
                      title: Text(item.productName),
                      subtitle: Text(
                        [
                          item.brand,
                          item.rating,
                          item.addedAt.toLocal().toString().split('.').first,
                        ].whereType<String>().join(' - '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/product/${item.barcode}'),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemCount: favorites.length,
              ),
      ),
    );
  }
}
