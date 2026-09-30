import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
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
    int? selectedCategoryId;

    // Salinan lokal yang bisa diperbarui saat menambah kategori baru di dialog
    var dialogCategories = List<CategoryModel>.from(
      context.read<ProductProvider>().categories,
    );

    if (dialogCategories.isNotEmpty) {
      selectedCategoryId = dialogCategories.first.id;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Produk'),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
                    // Dropdown Kategori + Tombol Tambah Kategori
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('add_cat_${dialogCategories.length}_$selectedCategoryId'),
                            initialValue: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: dialogCategories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCategoryId = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20), size: 28),
                          tooltip: 'Tambah Kategori Baru',
                          onPressed: () {
                            _showAddCategoryDialog(context, onCategoryAdded: (categories, newId) {
                              setDialogState(() {
                                dialogCategories = categories;
                                selectedCategoryId = newId;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                    if (selectedCategoryId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu')));
                      return;
                    }

                    try {
                      final newProduct = ProductModel(
                        categoryId: selectedCategoryId!,
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
      },
    );
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    int selectedCategoryId = product.categoryId;

    // Salinan lokal yang bisa diperbarui saat menambah kategori baru di dialog
    var dialogCategories = List<CategoryModel>.from(
      context.read<ProductProvider>().categories,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Produk'),
              content: SingleChildScrollView(
                child: Column(
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
                    const SizedBox(height: 16),
                    // Dropdown Kategori + Tombol Tambah Kategori
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('edit_cat_${dialogCategories.length}_$selectedCategoryId'),
                            initialValue: selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: dialogCategories.map((cat) {
                              return DropdownMenuItem<int>(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedCategoryId = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20), size: 28),
                          tooltip: 'Tambah Kategori Baru',
                          onPressed: () {
                            _showAddCategoryDialog(context, onCategoryAdded: (categories, newId) {
                              setDialogState(() {
                                dialogCategories = categories;
                                selectedCategoryId = newId;
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                        categoryId: selectedCategoryId,
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

  /// Dialog untuk menambah kategori baru
  /// [onCategoryAdded] dipanggil ketika kategori berhasil ditambah (digunakan oleh dialog produk)
  void _showAddCategoryDialog(BuildContext context, {Function(List<CategoryModel>, int)? onCategoryAdded}) {
    final categoryNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: categoryNameController,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Contoh: Minuman, Makanan, dll',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = categoryNameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  final provider = context.read<ProductProvider>();
                  final newId = await provider.addCategory(name);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kategori "$name" berhasil ditambahkan')),
                    );
                    onCategoryAdded?.call(provider.categories, newId);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menambah kategori: $e')),
                    );
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

  /// Dialog konfirmasi hapus kategori
  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (category.id == null) return;

                try {
                  final provider = context.read<ProductProvider>();
                  final productCount = await provider.getCategoryProductCount(category.id!);

                  if (productCount > 0) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tidak bisa menghapus "${category.name}" karena masih digunakan oleh $productCount produk. '
                            'Pindahkan produk ke kategori lain terlebih dahulu.',
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                    return;
                  }

                  await provider.deleteCategory(category.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kategori "${category.name}" berhasil dihapus')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus kategori: $e')),
                    );
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

  /// Mendapatkan nama kategori berdasarkan categoryId
  String _getCategoryName(List<CategoryModel> categories, int categoryId) {
    final cat = categories.where((c) => c.id == categoryId);
    return cat.isNotEmpty ? cat.first.name : '';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: Colors.white, // Warna background putih
      extendBodyBehindAppBar: true, // Membiarkan list berada di bawah appbar (untuk efek blur)
      extendBody: true, // Membiarkan list berada di bawah navigasi sistem
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70 + 36),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efek blur/translucent
            child: AppBar(
              toolbarHeight: 70,
              title: Image.asset('asset/logo_joko.png', height: 70, fit: BoxFit.contain),
              centerTitle: false,
              titleSpacing: 16,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    children: [
                      // Chip "Semua"
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Semua'),
                          selected: productProvider.selectedCategoryId == null,
                          selectedColor: const Color(0xFF1B5E20),
                          checkmarkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          labelStyle: TextStyle(
                            color: productProvider.selectedCategoryId == null
                                ? Colors.white
                                : const Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: productProvider.selectedCategoryId == null
                                  ? const Color(0xFF1B5E20)
                                  : Colors.transparent,
                            ),
                          ),
                          onSelected: (_) {
                            productProvider.selectCategory(null);
                          },
                        ),
                      ),
                      // Chip untuk setiap kategori (long-press untuk hapus)
                      ...productProvider.categories.map((category) {
                        final isSelected = productProvider.selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              _showDeleteCategoryDialog(context, category);
                            },
                            child: FilterChip(
                              label: Text(category.name),
                              selected: isSelected,
                              selectedColor: const Color(0xFF1B5E20),
                              checkmarkColor: Colors.white,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF1B5E20),
                                fontWeight: FontWeight.w600,
                              ),
                              backgroundColor: const Color(0xFFE8F5E9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF1B5E20)
                                      : Colors.transparent,
                                ),
                              ),
                              onSelected: (_) {
                                productProvider.selectCategory(category.id);
                              },
                            ),
                          ),
                        );
                      }),
                      // Chip "+" untuk tambah kategori baru
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.add, size: 18, color: Color(0xFF1B5E20)),
                          label: const Text('Baru'),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFF1B5E20),
                              style: BorderStyle.solid,
                              width: 0.5,
                            ),
                          ),
                          onPressed: () {
                            _showAddCategoryDialog(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
              }

              final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? (MediaQuery.of(context).padding.top + 70 + 36);

              if (productProvider.products.isEmpty) {
                return Padding(
                  padding: EdgeInsets.only(top: appBarHeight),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Belum ada produk.\nData akan muncul setelah ditambahkan ke Database.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(top: appBarHeight, bottom: 120, left: 16, right: 16),
                itemCount: productProvider.products.length,
                itemBuilder: (context, index) {
                  final product = productProvider.products[index];
                  final categoryName = _getCategoryName(
                    productProvider.categories,
                    product.categoryId,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currencyFormat.format(product.price),
                            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                          ),
                          if (categoryName.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                categoryName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
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

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Hitung tinggi minimum agar pas dengan konten header + area aman bawah
    // Header height: swipe indicator (20) + padding & content (~70)
    final collapsedHeight = 100.0 + bottomPadding;
    final minChildSize = (collapsedHeight / screenHeight).clamp(0.1, 0.5);

    return DraggableScrollableSheet(
      initialChildSize: minChildSize, 
      minChildSize: minChildSize,
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
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 8 + bottomPadding), // Tambahkan bottomPadding di sini agar aman dari tombol navigasi
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
