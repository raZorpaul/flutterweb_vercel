import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutterweb_vercel/pay_page.dart'; // Import the new PayPage

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
        useMaterial3: true, // Use Material 3 for modern UI
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
          children: <Widget>[
            const Text('Welcome to the UPI Scanner!'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRViewExample()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan UPI QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
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
  String _displayMessage = 'Scan a UPI QR code'; // Standardized variable name
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    // Platform.isAndroid check is removed for web-only focus
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () async {
              await controller?.flipCamera();
              setState(() {
                _displayMessage = 'Camera flipped';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {
                _displayMessage = 'Flash toggled';
              });
            },
          ),
        ],
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _displayMessage,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen(
      (scanData) {
        if (scanData.code == null || scanData.code!.isEmpty) {
          return;
        }

        if (_isProcessing) return;

        _isProcessing = true;

        controller.pauseCamera();

        String code = scanData.code!;

        if (code.startsWith('upi://pay')) {
          try {
            final uri = Uri.parse(code);
            final params = uri.queryParameters;

            final upiDetails = UpiDetails(
              payeeAddress: params['pa'] ?? 'N/A',
              payeeName: Uri.decodeComponent(params['pn'] ?? 'N/A'),
              amount: params['am'],
              transactionNote: params['tn'],
              merchantCode: params['mc'],
              transactionRef: params['tr'],
            );

            // Navigate to the PayPage with UPI details
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PayPage(upiDetails: upiDetails),
              ),
            );

          } catch (e) {
            setState(() {
              _displayMessage = 'Error parsing UPI: $e';
            });
          }
        } else {
          setState(() {
            _displayMessage = '''Error: Not a UPI Code\n\nScanned: ${code.substring(0, code.length > 50 ? 50 : code.length)}...''';
          });
        }

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && controller != null) {
            controller!.resumeCamera();
            setState(() {
              _displayMessage = 'Ready to scan again!';
            });
          }
          _isProcessing = false;
        });
      },
      onError: (error) {
        setState(() {
          _displayMessage = 'Scanner error: $error';
        });
      },
      onDone: () {
        // Stream closed, possibly unmount QRView
      },
    );
  }
}