import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class PrinterHelper {
  static Future<void> printReceipt({
    required List<CartItem> items,
    required int totalAmount,
    required String paymentMethod,
    required int cashAmount,
    required int change,
  }) async {
    BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
    bool? isConnected = await bluetooth.isConnected;

    if (isConnected != true) {
      return;
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Print Header
    bluetooth.printCustom("COFFEE POS", 3, 1);
    bluetooth.printCustom("Jl. Raya Ngopi No. 1", 1, 1);
    bluetooth.printCustom("Telp: 081234567890", 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Info Transaksi
    bluetooth.printCustom(dateFormat.format(DateTime.now()), 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    for (var item in items) {
      bluetooth.printCustom(item.product.name, 1, 0);
      String priceStr = "${item.qty} x ${currencyFormat.format(item.product.price)}";
      String subtotalStr = currencyFormat.format(item.subtotal);
      
      // Calculate spaces for right alignment
      bluetooth.printLeftRight(priceStr, subtotalStr, 1);
      
      if (item.notes != null && item.notes!.isNotEmpty) {
        bluetooth.printCustom("  Catatan: ${item.notes}", 1, 0);
      }
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Totals
    bluetooth.printLeftRight("TOTAL", currencyFormat.format(totalAmount), 1);
    bluetooth.printLeftRight("PEMBAYARAN", paymentMethod, 1);
    
    if (paymentMethod == 'CASH') {
      bluetooth.printLeftRight("TUNAI", currencyFormat.format(cashAmount), 1);
      bluetooth.printLeftRight("KEMBALI", currencyFormat.format(change), 1);
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printCustom("Terima Kasih", 1, 1);
    bluetooth.printCustom("Selamat Menikmati", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine(); // Paper feed
  }
}
