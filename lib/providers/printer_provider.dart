import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class PrinterProvider with ChangeNotifier {
  BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isBluetoothEnabled = false;

  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  PrinterProvider() {
    initPrinter();
  }

  Future<void> initPrinter() async {
    bool? isConnected = await _bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await _bluetooth.getBondedDevices();
      _isBluetoothEnabled = true;
    } on PlatformException {
      _isBluetoothEnabled = false;
    }

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          _isConnected = true;
          notifyListeners();
          break;
        case BlueThermalPrinter.DISCONNECTED:
          _isConnected = false;
          _selectedDevice = null;
          notifyListeners();
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
        case BlueThermalPrinter.STATE_OFF:
          _isConnected = false;
          _isBluetoothEnabled = false;
          _selectedDevice = null;
          notifyListeners();
          break;
        case BlueThermalPrinter.STATE_ON:
          _isBluetoothEnabled = true;
          scanDevices();
          notifyListeners();
          break;
        default:
          break;
      }
    });

    _devices = devices;
    _isConnected = isConnected ?? false;
    notifyListeners();
  }

  Future<void> scanDevices() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      _devices = devices;
      notifyListeners();
    } on PlatformException {
      // Handle error
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_isConnected) {
      await _bluetooth.disconnect();
    }

    try {
      await _bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _bluetooth.disconnect();
    _selectedDevice = null;
    _isConnected = false;
    notifyListeners();
  }
}
