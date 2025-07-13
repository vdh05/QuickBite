import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  // Initialize cart as empty by default
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.menuItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      // Increase quantity if item already exists
      _items.update(
        menuItem.id,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      // Add new item with quantity 1
      _items.putIfAbsent(
        menuItem.id,
        () => CartItem(menuItem: menuItem),
      );
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.remove(menuItemId);
    notifyListeners();
  }

  void decreaseQuantity(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    
    if (_items[menuItemId]!.quantity > 1) {
      _items.update(
        menuItemId,
        (existingItem) => CartItem(
          menuItem: existingItem.menuItem,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(menuItemId);
    }
    
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
