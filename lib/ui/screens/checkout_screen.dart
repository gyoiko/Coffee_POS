import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/printer_helper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _cashController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _showEditNoteDialog(BuildContext context, int index, String? currentNotes) {
    final notesController = TextEditingController(text: currentNotes);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Catatan'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Misal: Gula sedikit, tanpa es',
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CartProvider>().updateNotes(index, notesController.text);
                Navigator.pop(context);
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
    final cart = context.watch<CartProvider>();
    final transaction = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang kosong'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Ringkasan Pesanan
                const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${currencyFormat.format(item.product.price)}  |  Sub: ${currencyFormat.format(item.subtotal)}'),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text('Catatan: ${item.notes}', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.orange),
                              onPressed: () {
                                _showEditNoteDialog(context, index, item.notes);
                              },
                            ),
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
                const SizedBox(height: 16),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Tagihan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(currencyFormat.format(cart.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  ],
                ),
                const SizedBox(height: 24),

                // Metode Pembayaran
                const Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Tunai'),
                        value: 'CASH',
                        groupValue: transaction.paymentMethod,
                        onChanged: (val) => transaction.setPaymentMethod(val!),
                        activeColor: const Color(0xFF1B5E20),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('QRIS'),
                        value: 'QRIS',
                        groupValue: transaction.paymentMethod,
                        onChanged: (val) => transaction.setPaymentMethod(val!),
                        activeColor: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),

                if (transaction.paymentMethod == 'CASH') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Uang Tunai Diterima',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1B5E20))),
                      prefixText: 'Rp ',
                    ),
                    onChanged: (val) {
                      int amount = int.tryParse(val) ?? 0;
                      transaction.setCashAmount(amount);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kembalian: ${currencyFormat.format(transaction.calculateChange(cart.totalAmount))}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction.calculateChange(cart.totalAmount) >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            if (cart.items.isEmpty) return;
            if (transaction.paymentMethod == 'CASH' && transaction.cashAmount < cart.totalAmount) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang tunai kurang!')));
              return;
            }
            
            bool success = await context.read<TransactionProvider>().processCheckout(cart.items, cart.totalAmount);
            if (success) {
              // Copy data before clearing
              final printedItems = List<CartItem>.from(cart.items);
              final printedTotal = cart.totalAmount;
              final printedPaymentMethod = transaction.paymentMethod;
              final printedCashAmount = transaction.cashAmount;
              final printedChange = transaction.calculateChange(printedTotal);

              cart.clearCart();
              transaction.resetPayment();
              
              if (context.mounted) {
                // Check printer connection first
                bool? isPrinterConnected = await BlueThermalPrinter.instance.isConnected;
                
                if (isPrinterConnected == true) {
                  // Show Print Dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: const Text('Cetak Struk?'),
                        content: const Text('Transaksi berhasil disimpan. Apakah Anda ingin mencetak struk?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context); // Kembali ke Home
                            },
                            child: const Text('Tidak'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await PrinterHelper.printReceipt(
                                items: printedItems,
                                totalAmount: printedTotal,
                                paymentMethod: printedPaymentMethod,
                                cashAmount: printedCashAmount,
                                change: printedChange,
                              );
                              if (context.mounted) Navigator.pop(context); // Kembali ke Home
                            },
                            child: const Text('Cetak'),
                          ),
                        ],
                      );
                    }
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil disimpan!')));
                  Navigator.pop(context); // Kembali ke Home
                }
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses transaksi')));
              }
            }
          },
          child: transaction.isProcessing 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('PROSES PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
