import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';

/// Simulated locally stateful Economy service managing currency balances, unlocks, and item inventory.
class EconomyService {
  int _coins = 500; // Starting mock balance
  final Set<String> _ownedItemIds = {'classic_brush', 'rookie_badge'};

  int get coins => _coins;
  List<String> get ownedItems => _ownedItemIds.toList();

  /// Adds coins to the balance.
  void addCoins(int amount) {
    if (amount > 0) {
      _coins += amount;
    }
  }

  /// Verifies ownership of an unlockable item.
  bool ownsItem(String itemId) => _ownedItemIds.contains(itemId);

  /// Performs a store purchase using simulated currency.
  bool purchaseItem(ShopItem item) {
    if (_ownedItemIds.contains(item.id)) return true; // Already owned

    if (_coins >= item.price) {
      _coins -= item.price;
      _ownedItemIds.add(item.id);
      return true;
    }
    return false; // Insufficient funds
  }

  /// Force unlocks an item (e.g. earned via season level-ups or mission rewards).
  void grantItem(String itemId) {
    _ownedItemIds.add(itemId);
  }

  /// Resets the economy values back to factory defaults.
  void reset() {
    _coins = 500;
    _ownedItemIds.clear();
    _ownedItemIds.addAll(['classic_brush', 'rookie_badge']);
  }
}
