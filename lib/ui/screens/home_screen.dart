import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'report_screen.dart';
import 'printer_setting_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama produk tidak boleh kosong')));
                  return;
                }
                if (price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga produk tidak valid')));
                  return;
                }

                try {
                  final newProduct = ProductModel(
                    categoryId: 1, // Kategori default
                    name: name,
                    price: price,
                  );
                  await context.read<ProductProvider>().addProduct(newProduct);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil ditambahkan')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white, // Warna background putih
      extendBodyBehindAppBar: true, // Membiarkan list berada di bawah appbar (untuk efek blur)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efek blur/translucent
            child: AppBar(
              title: const Text('Coffee POS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              centerTitle: true,
              backgroundColor: const Color(0xB2FFFFFF), // Putih transparan
              actions: [
                IconButton(
                  icon: const Icon(Icons.print, color: Color(0xFF1B5E20)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingScreen()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1B5E20)),
                  onPressed: () {
                    _showAddProductDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Color(0xFF1B5E20)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                  },
                )
              ],
            ),
          ),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          if (productProvider.products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Belum ada produk.\nData akan muncul setelah ditambahkan ke Database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 100, bottom: 120, left: 16, right: 16),
            itemCount: productProvider.products.length,
            itemBuilder: (context, index) {
              final product = productProvider.products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x0A000000),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Hijau sangat muda
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.coffee, color: Color(0xFF2E7D32)),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    currencyFormat.format(product.price),
                    style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20), // Hijau Tua
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      context.read<CartProvider>().addToCart(product);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomSheet: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return const SizedBox.shrink();

          // Panel Bawah Melayang (Floating Blur Panel) untuk Keranjang
          return ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efek blur keranjang
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xD91B5E20), // Hijau Tua Translucent
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalItemCount} Item di Keranjang',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            currencyFormat.format(cart.totalAmount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
