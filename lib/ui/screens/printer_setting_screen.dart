import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';
import '../../providers/printer_provider.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  void _testPrint(BuildContext context) async {
    final printerProvider = Provider.of<PrinterProvider>(context, listen: false);
    
    if (!printerProvider.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada printer yang terhubung')),
      );
      return;
    }

    BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
    bluetooth.printCustom("TEST PRINT Berhasil", 2, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine(); // Feed paper
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
      ),
      body: Consumer<PrinterProvider>(
        builder: (context, printerProvider, child) {
          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bluetooth, color: Color(0xFF1B5E20)),
                        SizedBox(width: 12),
                        Text('Status Bluetooth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      printerProvider.isBluetoothEnabled ? "Aktif" : "Mati",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: printerProvider.isBluetoothEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (printerProvider.isBluetoothEnabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Perangkat Tersedia (Bonded)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextButton.icon(
                        onPressed: () => printerProvider.scanDevices(),
                        icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
                        label: const Text('Refresh', style: TextStyle(color: Color(0xFF2E7D32))),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: printerProvider.devices.isEmpty
                      ? const Center(child: Text("Tidak ada perangkat bluetooth yang dipasangkan."))
                      : ListView.builder(
                          itemCount: printerProvider.devices.length,
                          itemBuilder: (context, index) {
                            final device = printerProvider.devices[index];
                            final isConnected = printerProvider.isConnected && 
                                printerProvider.selectedDevice?.address == device.address;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isConnected ? const Color(0xFF1B5E20) : Colors.grey.shade300, width: isConnected ? 2 : 1),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.print,
                                  color: isConnected ? const Color(0xFF1B5E20) : Colors.grey,
                                ),
                                title: Text(device.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${device.address}\n${isConnected ? 'Terhubung' : 'Tersedia'}'),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isConnected ? Colors.red.shade100 : const Color(0xFFE8F5E9),
                                    foregroundColor: isConnected ? Colors.red : const Color(0xFF1B5E20),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    if (isConnected) {
                                      await printerProvider.disconnect();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Menghubungkan ke ${device.name}...')),
                                      );
                                      bool success = await printerProvider.connectToDevice(device);
                                      if (mounted) {
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Berhasil terhubung dengan ${device.name}')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Gagal menghubungkan ke printer')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Text(isConnected ? 'Putus' : 'Hubungkan'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Test Print Struk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () => _testPrint(context),
                  ),
                )
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Nyalakan Bluetooth pada perangkat Anda', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              ]
            ],
          );
        },
      ),
    );
  }
}
