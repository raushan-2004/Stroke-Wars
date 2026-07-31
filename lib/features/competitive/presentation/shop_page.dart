import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';
import 'package:stroke_wars/features/competitive/providers/competitive_providers.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final List<ShopItem> _catalog = const [
    ShopItem(
      id: 'frame_gold',
      title: 'Gilded Frame',
      category: 'frame',
      price: 200,
      currency: 'Coins',
      isAnimated: false,
    ),
    ShopItem(
      id: 'brush_neon',
      title: 'Neon Brush Skin',
      category: 'brush',
      price: 350,
      currency: 'Coins',
      isAnimated: true,
    ),
    ShopItem(
      id: 'theme_cyber',
      title: 'Cyberpunk Theme',
      category: 'theme',
      price: 500,
      currency: 'Coins',
      isAnimated: false,
    ),
    ShopItem(
      id: 'badge_pro',
      title: 'Pro Badge',
      category: 'badge',
      price: 150,
      currency: 'Coins',
      isAnimated: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final economy = ref.watch(economyServiceProvider);
    final notifications = ref.read(notificationCenterProvider);
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Cosmetics Store', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: colors.background,
        padding: EdgeInsets.all(spacing.md.r),
        child: Column(
          children: [
            // Balance card
            _buildBalanceHeader(context, economy),

            SizedBox(height: spacing.md.r),

            // Store catalog grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: spacing.md.r,
                  mainAxisSpacing: spacing.md.r,
                  childAspectRatio: 1.3,
                ),
                itemCount: _catalog.length,
                itemBuilder: (context, index) {
                  final item = _catalog[index];
                  final owned = economy.ownsItem(item.id);

                  return SWGlassCard(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SWBadge(
                                label: item.category.toUpperCase(),
                                color: colors.primary,
                              ),
                              SizedBox(height: spacing.xs.r),
                              Text(
                                item.title,
                                style: typography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.isAnimated)
                                Text(
                                  'Animated',
                                  style: typography.caption.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                owned ? 'OWNED' : '${item.price} Coins',
                                style: typography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: owned
                                      ? colors.textMuted
                                      : Colors.amber,
                                ),
                              ),
                              if (!owned)
                                ElevatedButton(
                                  onPressed: () {
                                    final success = economy.purchaseItem(item);
                                    if (success) {
                                      notifications.postNotification(
                                        title: 'Item Unlocked!',
                                        body:
                                            'Unlocked cosmetics skin: "${item.title}" successfully!',
                                        type: 'shop_unlock',
                                      );
                                      setState(() {});
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Purchased ${item.title}!',
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Insufficient balance!',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.sm.r,
                                    ),
                                  ),
                                  child: const Text('Unlock'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, dynamic economy) {
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return SWGlassCard(
      child: Padding(
        padding: EdgeInsets.all(spacing.md.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cosmetics locker balances:',
              style: typography.body.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${economy.coins} Coins',
              style: typography.heading.copyWith(
                color: Colors.amber,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
