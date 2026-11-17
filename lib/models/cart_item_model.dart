import 'package:ngekas/models/product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  int get subtotal => product.sellPrice * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) =>
      CartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);
}
