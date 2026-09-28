import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isBluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
      _isBluetoothEnabled = true;
    } on PlatformException {
      _isBluetoothEnabled = false;
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            _device = null;
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            _isBluetoothEnabled = false;
            _device = null;
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _isBluetoothEnabled = true;
          });
          _scanDevices();
          break;
        default:
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
      _connected = isConnected ?? false;
    });
  }

  void _scanDevices() async {
    setState(() {});
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
      });
    } on PlatformException {
      // Handle error
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    if (_connected) {
      await bluetooth.disconnect();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Menghubungkan ke ${device.name}...')),
    );

    try {
      await bluetooth.connect(device);
      setState(() {
        _device = device;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil terhubung dengan ${device.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghubungkan ke printer')),
        );
      }
    }
  }

  void _disconnect() async {
    await bluetooth.disconnect();
    setState(() {
      _device = null;
      _connected = false;
    });
  }

  void _testPrint() async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada printer yang terhubung')),
      );
      return;
    }

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
      body: Column(
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
                  _isBluetoothEnabled ? "Aktif" : "Mati",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isBluetoothEnabled ? Colors.green : Colors.red,
                  ),
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
                  const Text('Perangkat Tersedia (Bonded)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextButton.icon(
                    onPressed: _scanDevices,
                    icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
                    label: const Text('Refresh', style: TextStyle(color: Color(0xFF2E7D32))),
                  )
                ],
              ),
            ),
            Expanded(
              child: _devices.isEmpty
                  ? const Center(child: Text("Tidak ada perangkat bluetooth yang dipasangkan."))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isConnected = _connected && _device?.address == device.address;
                        
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
                              onPressed: () {
                                if (isConnected) {
                                  _disconnect();
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
                    Text('Nyalakan Bluetooth pada perangkat Anda', style: TextStyle(color: Colors.grey)),
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
