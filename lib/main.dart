import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/report_provider.dart';
import 'providers/product_provider.dart';
import 'providers/printer_provider.dart';
import 'ui/screens/home_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()),
      ],
      child: MaterialApp(
        title: 'RANS Coffee POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6F4E37)), // Coffee Brown
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}