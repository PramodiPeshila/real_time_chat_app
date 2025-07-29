import 'package:flutter/material.dart';
import 'package:realtime_chat_app/components/footer.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Center(
        child: const Text('QR Scanner will be implemented here'),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
