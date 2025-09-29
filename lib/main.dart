import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRViewExample()),
          );
        },
        tooltip: 'Scan QR Code',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String displayText = 'Camera ready! Point at QR code';

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    print('🟢 [CONSOLE] QR Controller created and listening...');
    
    controller.scannedDataStream.listen((scanData) {
      print('🔵 [CONSOLE] Stream received data');
      
      if (scanData.code != null && scanData.code!.isNotEmpty) {
        String code = scanData.code!;
        print('🟡 [CONSOLE] QR Code scanned: $code');
        
        if (code.startsWith('upi://pay')) {
          print('🟢 [CONSOLE] Detected UPI code!');
          try {
            final uri = Uri.parse(code);
            final params = uri.queryParameters;
            print('🔵 [CONSOLE] Parsed parameters: $params');
            
            if (params['pa'] != null) {
              print('✅ [CONSOLE] UPI ID found: ${params['pa']}');
              setState(() {
                displayText = params['pa']!;
              });
              print('🟢 [CONSOLE] Display updated to: ${params['pa']}');
              
              // Navigate to payment page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentPage(upiId: params['pa']!),
                ),
              );
            } else {
              print('⚠️ [CONSOLE] No UPI ID (pa) parameter found');
            }
          } catch (e) {
            print('❌ [CONSOLE] Error parsing UPI: $e');
          }
        } else {
          print('⚠️ [CONSOLE] Not a UPI QR code (doesn\'t start with upi://pay)');
        }
      } else {
        print('⚠️ [CONSOLE] Received null or empty scan data');
      }
    });
  }
}