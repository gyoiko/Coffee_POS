import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../providers/cart_provider.dart';

class PrinterHelper {
  static Future<void> _printLogo(BlueThermalPrinter bluetooth) async {
    try {
      final ByteData data = await rootBundle.load('asset/logo_joko.png');
      final Uint8List bytes = data.buffer.asUint8List();
      
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        // Resize logo lebar 200px (Kertas 58mm lebar max 384px)
        img.Image resizedImage = img.copyResize(originalImage, width: 200);
        
        // Buat canvas putih lebar 384px agar logo persis di tengah
        img.Image canvas = img.Image(width: 384, height: resizedImage.height);
        img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
        
        // Gabungkan logo ke tengah canvas
        img.compositeImage(canvas, resizedImage, dstX: (384 - 200) ~/ 2, dstY: 0);
        
        // Konversi manual ke monokrom dengan threshold rendah (180)
        // agar warna hijau muda "Jo." tidak hilang saat di-print
        // Threshold 180 artinya: pixel yang grayscale-nya < 180 akan jadi HITAM
        img.Image bwCanvas = img.Image(width: canvas.width, height: canvas.height);
        for (int y = 0; y < canvas.height; y++) {
          for (int x = 0; x < canvas.width; x++) {
            final pixel = canvas.getPixel(x, y);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            // Hitung grayscale (luminance)
            final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
            // Threshold 180: warna hijau sage (~rgb(130,148,108)) -> gray ~138 -> HITAM
            if (gray < 180) {
              bwCanvas.setPixelRgb(x, y, 0, 0, 0); // Hitam
            } else {
              bwCanvas.setPixelRgb(x, y, 255, 255, 255); // Putih
            }
          }
        }
        
        // Gunakan esc_pos_utils_plus untuk generate raw thermal commands
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        
        final List<int> rasterBytes = generator.imageRaster(bwCanvas);
        
        // Tembak perintah mentah langsung ke printer
        bluetooth.writeBytes(Uint8List.fromList(rasterBytes));
      }
    } catch (e) {
      print('Error loading/processing logo: $e');
    }
  }

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

    // Print Logo (Sudah di-resize & ditaruh di tengah)
    await _printLogo(bluetooth);

    // Print Header (Tanpa Jo.Ko)
    bluetooth.printCustom("Gg. Adil I, Ngilir, Kota Kendal, Jawa Tengah", 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Info Transaksi
    bluetooth.printCustom(dateFormat.format(DateTime.now()), 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    for (var item in items) {
      bluetooth.printCustom(item.product.name, 1, 0);
      String priceStr = "${item.qty} x ${currencyFormat.format(item.product.price)}";
      String subtotalStr = currencyFormat.format(item.subtotal);
      
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
    bluetooth.printCustom("Terima Kasih atas kunjungan Anda", 1, 1);
    bluetooth.printCustom("Selamat Menikmati", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }

  static Future<void> printReceiptFromHistory({
    required dynamic transaction, 
  }) async {
    BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
    bool? isConnected = await bluetooth.isConnected;

    if (isConnected != true) {
      return;
    }

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Print Logo
    await _printLogo(bluetooth);

    // Print Header
    bluetooth.printCustom("Gg. Adil I, Ngilir, Kota Kendal, Jawa Tengah", 1, 1);
    bluetooth.printCustom("Telp: 0813-2728-2212", 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Info Transaksi
    bluetooth.printCustom("ID: ${transaction.transactionCode}", 1, 1);
    bluetooth.printCustom(dateFormat.format(transaction.createdAt), 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Items
    if (transaction.items != null) {
      for (var item in transaction.items!) {
        bluetooth.printCustom(item.productName, 1, 0);
        String priceStr = "${item.qty} x ${currencyFormat.format(item.price)}";
        String subtotalStr = currencyFormat.format(item.subtotal);
        
        bluetooth.printLeftRight(priceStr, subtotalStr, 1);
        
        if (item.notes != null && item.notes!.isNotEmpty) {
          bluetooth.printCustom("  Catatan: ${item.notes}", 1, 0);
        }
      }
    }
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    
    // Totals
    bluetooth.printLeftRight("TOTAL", currencyFormat.format(transaction.totalAmount), 1);
    bluetooth.printLeftRight("PEMBAYARAN", transaction.paymentMethod, 1);
    bluetooth.printCustom("(SALINAN / REPRINT)", 1, 1);
    
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printCustom("Terima Kasih atas kunjungan Anda", 1, 1);
    bluetooth.printCustom("Selamat Menikmati", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }
}
