import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../../providers/report_provider.dart';
import '../../utils/printer_helper.dart';
import '../../providers/printer_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().setFilterMode(ReportFilterMode.daily);
    });
  }

  Future<void> _selectDate(BuildContext context, ReportProvider report) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: report.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != report.selectedDate) {
      report.setSelectedDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Laporan Penjualan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export ke Excel',
            onPressed: () async {
              final path = await context.read<ReportProvider>().exportToExcel();
              if (context.mounted) {
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil diekspor ke: $path')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengekspor laporan')));
                }
              }
            },
          )
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, report, child) {
          return Column(
            children: [
              // Filter Toggle (Harian / Bulanan)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ReportFilterMode>(
                        segments: const [
                          ButtonSegment(value: ReportFilterMode.daily, label: Text('Harian')),
                          ButtonSegment(value: ReportFilterMode.monthly, label: Text('Bulanan')),
                        ],
                        selected: {report.filterMode},
                        onSelectionChanged: (Set<ReportFilterMode> newSelection) {
                          report.setFilterMode(newSelection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF2E7D32)),
                      onPressed: () => _selectDate(context, report),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: report.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            color: const Color(0xFF1B5E20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    report.filterMode == ReportFilterMode.daily 
                                        ? 'Pendapatan Hari Ini (${DateFormat('dd MMM yyyy').format(report.selectedDate)})'
                                        : 'Pendapatan Bulan Ini (${DateFormat('MMM yyyy').format(report.selectedDate)})',
                                    style: const TextStyle(color: Colors.white70)
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormat.format(report.summary['total_revenue'] ?? 0),
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white30),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Cash', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          Text(currencyFormat.format(report.summary['total_cash'] ?? 0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text('QRIS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          Text(currencyFormat.format(report.summary['total_qris'] ?? 0), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 10 Produk Terlaris
                          const Text('Produk Terlaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (report.topProducts.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data terlaris.'))),
                          ...report.topProducts.map((p) {
                            return Card(
                              color: Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                              child: ListTile(
                                leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.local_cafe, color: Color(0xFF2E7D32))),
                                title: Text(p['product_name']),
                                trailing: Text('${p['total_qty']} terjual', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 24),
                          
                          // Daftar Transaksi Harian (Hanya Tampil Jika Mode Harian)
                          if (report.filterMode == ReportFilterMode.daily) ...[
                            const Text('Riwayat Transaksi Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (report.transactions.isEmpty)
                              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada transaksi hari ini.'))),
                            
                            ...report.transactions.map((tx) {
                              return Card(
                                color: Colors.white,
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                                child: ExpansionTile(
                                  title: Text(tx.transactionCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(DateFormat('HH:mm').format(tx.createdAt) + ' - ' + tx.paymentMethod),
                                  trailing: Text(currencyFormat.format(tx.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                                  children: [
                                    if (tx.items != null)
                                      ...tx.items!.map((item) => ListTile(
                                        dense: true,
                                        title: Text(item.productName),
                                        subtitle: (item.notes != null && item.notes!.isNotEmpty)
                                            ? Text(
                                                'Catatan: ${item.notes}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                ),
                                              )
                                            : null,
                                        leading: Text('${item.qty}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        trailing: Text(currencyFormat.format(item.subtotal)),
                                      )),
                                    const Divider(),
                                    TextButton.icon(
                                      onPressed: () async {
                                        final printerProvider = context.read<PrinterProvider>();
                                        if (printerProvider.isConnected) {
                                          await PrinterHelper.printReceiptFromHistory(transaction: tx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak struk...')));
                                          }
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer belum terhubung! Silakan ke menu Pengaturan Printer.')));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.print, color: Color(0xFF1B5E20)),
                                      label: const Text('Cetak Struk', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            }),
                          ]
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
