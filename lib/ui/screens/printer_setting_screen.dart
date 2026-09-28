import 'package:flutter/material.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  bool _isBluetoothEnabled = false;
  bool _isScanning = false;
  
  // Dummy data for UI showcase
  final List<Map<String, String>> _devices = [
    {'name': 'InnerPrinter', 'mac': '00:11:22:33:44:55', 'status': 'Terhubung'},
    {'name': 'MTP-II', 'mac': '66:77:88:99:AA:BB', 'status': 'Tersedia'},
    {'name': 'POS-58', 'mac': 'CC:DD:EE:FF:00:11', 'status': 'Tersedia'},
  ];

  void _toggleBluetooth(bool value) {
    setState(() {
      _isBluetoothEnabled = value;
      if (!value) {
        _isScanning = false;
      }
    });
  }

  void _scanDevices() {
    if (!_isBluetoothEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktifkan Bluetooth terlebih dahulu')),
      );
      return;
    }
    
    setState(() {
      _isScanning = true;
    });
    
    // Simulate scanning
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pencarian perangkat selesai')),
        );
      }
    });
  }

  void _connectToDevice(Map<String, String> device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mencoba menghubungkan ke ${device['name']}...')),
    );
    // Simulate connection
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          for (var d in _devices) {
            if (d['mac'] == device['mac']) {
              d['status'] = 'Terhubung';
            } else {
              if (d['status'] == 'Terhubung') d['status'] = 'Tersedia';
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil terhubung dengan ${device['name']}')),
        );
      }
    });
  }

  void _testPrint() {
    final connectedDevice = _devices.firstWhere(
      (d) => d['status'] == 'Terhubung',
      orElse: () => {},
    );

    if (connectedDevice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada printer yang terhubung')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mencetak struk tes...')),
    );
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bluetooth, color: Color(0xFF1B5E20)),
                    SizedBox(width: 12),
                    Text('Bluetooth Printer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch(
                  value: _isBluetoothEnabled,
                  onChanged: _toggleBluetooth,
                  activeColor: const Color(0xFF1B5E20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isBluetoothEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Perangkat Tersedia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon: _isScanning 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
                    label: Text(_isScanning ? 'Mencari...' : 'Cari Perangkat', style: const TextStyle(color: Color(0xFF2E7D32))),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final isConnected = device['status'] == 'Terhubung';
                  
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
                      title: Text(device['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${device['mac']}\n${device['status']}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? Colors.red.shade100 : const Color(0xFFE8F5E9),
                          foregroundColor: isConnected ? Colors.red : const Color(0xFF1B5E20),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (isConnected) {
                            setState(() {
                              device['status'] = 'Tersedia';
                            });
                          } else {
                            _connectToDevice(device);
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
                onPressed: _testPrint,
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
                    Text('Nyalakan Bluetooth untuk mencari printer thermal', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
}
