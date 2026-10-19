import 'package:ngekas/models/product_model.dart';

// ─── CartItem ───────────────────────────────────────────────────────────────
//
// Satu baris di keranjang Kasir sebelum dibayar. Harga mengikuti harga jual
// barang saat ditambahkan ke keranjang.

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  int get subtotal => product.sellPrice * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) =>
      CartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);
}
