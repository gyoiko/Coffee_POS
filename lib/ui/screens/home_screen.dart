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

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
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
                  final updatedProduct = ProductModel(
                    id: product.id,
                    categoryId: product.categoryId,
                    name: name,
                    price: price,
                  );
                  await context.read<ProductProvider>().updateProduct(updatedProduct);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil diupdate')));
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

  void _showDeleteConfirmationDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: Text('Apakah Anda yakin ingin menghapus produk "${product.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (product.id != null) {
                  await context.read<ProductProvider>().deleteProduct(product.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk berhasil dihapus')));
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
      body: Stack(
        children: [
          Consumer<ProductProvider>(
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              _showEditProductDialog(context, product);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(context, product);
                            },
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20), // Hijau Tua
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              context.read<CartProvider>().addToCart(product);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SwipeableCartPanel(),
        ],
      ),
    );
  }
}

class SwipeableCartPanel extends StatelessWidget {
  const SwipeableCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    if (cart.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.13, 
      minChildSize: 0.13,
      maxChildSize: 0.6,
      snap: true,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B5E20), // Hijau Tua Solid
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indikator swipe (garis kecil)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 4),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Header Ringkasan
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.white,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const NeverScrollableScrollPhysics(), // Scroll diatur oleh CustomScrollView
                      itemCount: cart.items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${currencyFormat.format(item.product.price)} | Sub: ${currencyFormat.format(item.subtotal)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => context.read<CartProvider>().decrementQty(index),
                              ),
                              Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => context.read<CartProvider>().incrementQty(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => context.read<CartProvider>().removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
